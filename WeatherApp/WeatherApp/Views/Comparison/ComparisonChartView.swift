
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

    @State private var selectedTimestamp: Date?

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

    /// All distinct timestamps across sources — the grid the drag gesture snaps to.
    private var timestamps: [Date] {
        Set(seriesBySource.values.flatMap { $0.map(\.timestamp) }).sorted()
    }

    private func nearestTimestamp(to date: Date) -> Date? {
        timestamps.min(by: { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) })
    }

    /// Each source's value at the selected timestamp, highest first.
    private func values(at timestamp: Date) -> [(source: WeatherSource, value: Double)] {
        sourcesInOrder
            .compactMap { source in
                guard let point = seriesBySource[source]?.first(where: { $0.timestamp == timestamp }) else { return nil }
                return (source, point.value)
            }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        if sourcesInOrder.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 6) {
                selectionRow
                chart
            }
        }
    }

    /// Reserved row above the chart — shows per-source values while dragging,
    /// a hint otherwise. Kept out of the chart's own frame so it never covers the lines.
    private var selectionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let selectedTimestamp {
                    Text(selectedTimestamp, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(values(at: selectedTimestamp), id: \.source) { row in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(row.source.color)
                                .frame(width: 6, height: 6)
                            Text("\(row.source.shortName) \(Int(row.value.rounded()))\(metric.unit)")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                        }
                    }
                } else {
                    Text("Drag across the chart to compare providers")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(height: 16)
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

            if let selectedTimestamp {
                RuleMark(x: .value("Selected", selectedTimestamp))
                    .foregroundStyle(.primary.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                updateSelection(at: drag.location, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                selectedTimestamp = nil
                            }
                    )
            }
        }
        .animation(.easeOut(duration: 0.1), value: selectedTimestamp)
        .onChange(of: metric) {
            selectedTimestamp = nil
        }
        .frame(height: 200)
    }

    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let plotFrame = geometry[proxy.plotAreaFrame]
        let x = location.x - plotFrame.origin.x
        guard x >= 0, x <= plotFrame.width, let date: Date = proxy.value(atX: x) else { return }
        selectedTimestamp = nearestTimestamp(to: date)
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
