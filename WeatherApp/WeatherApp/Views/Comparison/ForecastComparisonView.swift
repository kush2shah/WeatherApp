
//
//  ForecastComparisonView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Redesigned forecast comparison view.
/// Leads with an agreement score, shows an uncertainty band chart,
/// per-source snapshot cards, and AI-style insight callouts.
struct ForecastComparisonView: View {
    let weatherData: WeatherData
    @State private var viewModel = ComparisonViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let data = viewModel.comparisonData {
                    VStack(spacing: 20) {
                        AgreementScoreHeader(data: data)
                        MetricSelectorRow(selected: $viewModel.selectedMetric)
                        UncertaintyChartSection(data: data, metric: viewModel.selectedMetric)
                        SourceSnapshotRow(weatherData: weatherData, outliers: data.outliers)
                        if !data.insights.isEmpty {
                            InsightSection(insights: data.insights)
                        }
                        SourceDetailSection(weatherData: weatherData)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                } else if let errorMessage = viewModel.analysisError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)
                        Text("Unable to compare forecasts")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Try Again") {
                            viewModel.analyzeWeatherData(weatherData)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                }
            }
            .navigationTitle("Compare Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.analyzeWeatherData(weatherData)
            }
        }
    }
}

// MARK: - Agreement Score Header

private struct AgreementScoreHeader: View {
    let data: ComparisonData

    private var scoreColor: Color {
        if data.agreementScore >= 80 { return .green }
        if data.agreementScore >= 50 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        if data.agreementScore >= 80 { return "High agreement" }
        if data.agreementScore >= 50 { return "Moderate uncertainty" }
        return "High uncertainty"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Score dial
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 6)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: CGFloat(data.agreementScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                    .animation(.easeOut(duration: 0.8), value: data.agreementScore)
                VStack(spacing: 0) {
                    Text("\(data.agreementScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text("%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Source Agreement")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                Text(scoreLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("\(data.sourceCount) sources · 24-hour window")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

// MARK: - Metric Selector

private struct MetricSelectorRow: View {
    @Binding var selected: ComparisonMetric

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ComparisonMetric.allCases) { metric in
                    MetricPill(metric: metric, isSelected: selected == metric) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = metric
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }
}

private struct MetricPill: View {
    let metric: ComparisonMetric
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                Text(metric.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(isSelected ? .regular.interactive() : .regular)
            .foregroundStyle(isSelected ? Color.primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Uncertainty Chart Section

private struct UncertaintyChartSection: View {
    let data: ComparisonData
    let metric: ComparisonMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "24-Hour Forecast Range")
                Spacer()
                Text("Shaded band = spread between sources")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            ComparisonChartView(data: data, metric: metric)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

// MARK: - Source Snapshot Cards

private struct SourceSnapshotRow: View {
    let weatherData: WeatherData
    let outliers: [SourceOutlier]

    private var outlierSources: Set<WeatherSource> {
        Set(outliers.map { $0.source })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Right Now")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weatherData.availableSources, id: \.self) { source in
                        if let weather = weatherData.sources[source] {
                            SourceNowCard(
                                source: source,
                                weather: weather,
                                isOutlier: outlierSources.contains(source)
                            )
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }
}

private struct SourceNowCard: View {
    let source: WeatherSource
    let weather: SourcedWeatherInfo
    let isOutlier: Bool

    private var sourceColor: Color {
        switch source {
        case .weatherKit:    return .blue
        case .googleWeather: return .red
        case .noaa:          return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO:    return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color accent bar
            Rectangle()
                .fill(sourceColor)
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.bottom, 10)

            // Temperature
            Text(weather.current.temperature.fahrenheitString)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Condition
            Label(weather.current.conditionDescription, systemImage: weather.current.condition.sfSymbolName)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.multicolor)
                .lineLimit(1)
                .padding(.top, 4)

            Spacer()

            // Source name + outlier badge
            HStack(spacing: 4) {
                Text(source.shortName)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(sourceColor)
                if isOutlier {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.top, 8)
        }
        .padding(14)
        .frame(width: 130, height: 130)
        .glassEffect(in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isOutlier ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Insights Section

private struct InsightSection: View {
    let insights: [ComparisonInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Insights")
            VStack(spacing: 1) {
                ForEach(insights) { insight in
                    InsightRow(insight: insight)
                    if insight.id != insights.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .glassEffect(in: .rect(cornerRadius: 24))
        }
    }
}

private struct InsightRow: View {
    let insight: ComparisonInsight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(insight.severity.color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(insight.detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Source Detail Section

private struct SourceDetailSection: View {
    let weatherData: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Source Details")
            VStack(spacing: 1) {
                ForEach(weatherData.availableSources, id: \.self) { source in
                    if let weather = weatherData.sources[source] {
                        ImprovedSourceDetailRow(source: source, weather: weather)
                        if source != weatherData.availableSources.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
            .glassEffect(in: .rect(cornerRadius: 24))

            // Attributions
            ForEach(weatherData.availableSources, id: \.self) { source in
                if let weather = weatherData.sources[source] {
                    Text(weather.attribution)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

private struct ImprovedSourceDetailRow: View {
    let source: WeatherSource
    let weather: SourcedWeatherInfo

    private var sourceColor: Color {
        switch source {
        case .weatherKit:    return .blue
        case .googleWeather: return .red
        case .noaa:          return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO:    return .purple
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Color accent
            Rectangle()
                .fill(sourceColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(source.displayName)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                    Spacer()
                    Text(weather.current.temperature.fahrenheitString)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                HStack(spacing: 12) {
                    Label(weather.current.conditionDescription, systemImage: weather.current.condition.sfSymbolName)
                        .symbolRenderingMode(.multicolor)
                    Spacer()
                    Label("\(weather.current.humidityPercentage)%", systemImage: "humidity")
                    Label("\(Int(weather.current.windSpeedMph)) mph", systemImage: "wind")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Shared Helpers

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }
}

private extension Double {
    /// Formats a Celsius temperature as a Fahrenheit string
    var fahrenheitString: String {
        let f = self * 9 / 5 + 32
        return "\(Int(f.rounded()))°"
    }
}
