
//
//  DailyDetailView.swift
//  WeatherApp
//

import SwiftUI
import Charts

/// Selection state for the source picker
enum SourceSelection: Hashable {
    case source(WeatherSource)
    case compare
}

/// Detail view for daily forecasts with swipeable day navigation.
/// Accepts the full array of forecasts and an initial index; users swipe
/// left/right to move between days without dismissing the sheet.
struct DailyDetailView: View {
    let forecasts: [DailyForecast]
    let initialIndex: Int
    let weatherData: WeatherData

    @State private var currentIndex: Int
    @State private var selection: SourceSelection
    @Environment(\.dismiss) private var dismiss

    init(forecasts: [DailyForecast], initialIndex: Int, weatherData: WeatherData) {
        self.forecasts = forecasts
        self.initialIndex = initialIndex
        self.weatherData = weatherData
        self._currentIndex = State(initialValue: initialIndex)
        let primary = weatherData.primarySource
        self._selection = State(initialValue: primary.map { .source($0) } ?? .compare)
    }

    private var currentForecast: DailyForecast {
        forecasts[min(currentIndex, forecasts.count - 1)]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day picker strip — tap to jump to any day
                dayPickerStrip
                    .padding(.vertical, 12)

                // Swipeable day pages
                TabView(selection: $currentIndex) {
                    ForEach(Array(forecasts.enumerated()), id: \.offset) { index, _ in
                        DayDetailPage(
                            forecast: forecasts[index],
                            weatherData: weatherData,
                            selection: $selection
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(currentForecast.dayOfWeek)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Day Picker Strip

    private var dayPickerStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(forecasts.enumerated()), id: \.offset) { index, forecast in
                        DayChip(
                            forecast: forecast,
                            isSelected: index == currentIndex
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentIndex = index
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: currentIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(currentIndex, anchor: .center)
            }
        }
    }
}

// MARK: - Day Chip

private struct DayChip: View {
    let forecast: DailyForecast
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(dayLabel)
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                WeatherIconView(condition: forecast.condition, size: 16)
                Text("\(Int((forecast.highTemperature * 9/5 + 32).rounded()))°")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .glassEffect(isSelected ? .regular.interactive() : .regular, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var dayLabel: String {
        Calendar.current.isDateInToday(forecast.date) ? "Today" : forecast.shortDayName
    }
}

// MARK: - Day Detail Page

/// Content for a single day — manages its own source selection state.
private struct DayDetailPage: View {
    let forecast: DailyForecast
    let weatherData: WeatherData
    @Binding var selection: SourceSelection
    private let formatter = WeatherFormatter.shared

    private var availableSources: [WeatherSource] { weatherData.availableSources }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                sourcePickerSection

                switch selection {
                case .source:
                    hourlyTimelineSection
                    conditionsGridSection
                case .compare:
                    comparisonSection
                }

                // Source attribution for the displayed data
                attributionFooter
            }
            .padding(.vertical)
        }

    }

    @ViewBuilder
    private var attributionFooter: some View {
        if case .source(let source) = selection {
            WeatherAttributionView(source: source)
                .padding(.top, 4)
        } else if availableSources.contains(.weatherKit) {
            AppleWeatherAttributionFooter()
                .padding(.top, 4)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(formatter.date(forecast.date, timezone: forecast.timezone, style: .long))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatter.temperature(forecast.highTemperature))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.medium)
                }

                WeatherIconView(condition: forecast.condition, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatter.temperature(forecast.lowTemperature))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(forecast.conditionDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Source Picker

    private var sourcePickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableSources, id: \.self) { source in
                    SourcePickerButton(
                        title: source.shortName,
                        isSelected: selection == .source(source)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = .source(source)
                        }
                    }
                }

                if availableSources.count > 1 {
                    SourcePickerButton(
                        title: "Compare",
                        isSelected: selection == .compare,
                        icon: "chart.bar.xaxis"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = .compare
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Hourly Timeline

    private enum TimelineItem: Identifiable {
        case hour(HourlyForecast)
        case sunrise(Date)
        case sunset(Date)

        var id: String {
            switch self {
            case .hour(let h): return h.id.uuidString
            case .sunrise(let d): return "sunrise-\(d.timeIntervalSince1970)"
            case .sunset(let d): return "sunset-\(d.timeIntervalSince1970)"
            }
        }

        var sortDate: Date {
            switch self {
            case .hour(let h): return h.timestamp
            case .sunrise(let d): return d
            case .sunset(let d): return d
            }
        }
    }

    private var hourlyForDay: [HourlyForecast] {
        guard case .source(let source) = selection,
              let weather = weatherData.weather(from: source) else { return [] }
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: forecast.date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        return weather.hourly.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
    }

    private var selectedDayForecast: DailyForecast {
        guard case .source(let source) = selection,
              let weather = weatherData.weather(from: source),
              let daily = weather.daily.first(where: { Calendar.current.isDate($0.date, inSameDayAs: forecast.date) }) else {
            return forecast
        }
        return daily
    }

    private var timelineItems: [TimelineItem] {
        let dayData = selectedDayForecast
        var items: [TimelineItem] = hourlyForDay.map { .hour($0) }
        if let sunrise = dayData.sunrise,
           let firstHour = hourlyForDay.first?.timestamp,
           let lastHour = hourlyForDay.last?.timestamp,
           sunrise >= firstHour && sunrise <= lastHour {
            items.append(.sunrise(sunrise))
        }
        if let sunset = dayData.sunset,
           let firstHour = hourlyForDay.first?.timestamp,
           let lastHour = hourlyForDay.last?.timestamp,
           sunset >= firstHour && sunset <= lastHour {
            items.append(.sunset(sunset))
        }
        return items.sorted { $0.sortDate < $1.sortDate }
    }

    @ViewBuilder
    private var hourlyTimelineSection: some View {
        if !hourlyForDay.isEmpty {
            let dayData = selectedDayForecast
            VStack(alignment: .leading, spacing: 12) {
                Label("Hourly", systemImage: "clock")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(timelineItems) { item in
                                switch item {
                                case .hour(let hour):
                                    DailyHourCell(
                                        hour: hour,
                                        timezone: forecast.timezone,
                                        isCurrentHour: Calendar.current.isDate(hour.timestamp, equalTo: Date(), toGranularity: .hour),
                                        sunrise: dayData.sunrise,
                                        sunset: dayData.sunset
                                    )
                                    .id(item.id)
                                case .sunrise(let time):
                                    SunEventCell(isSunrise: true, time: time, timezone: forecast.timezone)
                                        .id(item.id)
                                case .sunset(let time):
                                    SunEventCell(isSunrise: false, time: time, timezone: forecast.timezone)
                                        .id(item.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .onAppear {
                        if let currentHour = hourlyForDay.first(where: {
                            Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .hour)
                        }) {
                            proxy.scrollTo(currentHour.id.uuidString, anchor: .center)
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            .glassEffect(in: .rect(cornerRadius: 24))
            .padding(.horizontal)
        }
    }

    // MARK: - Conditions Grid

    private var conditionsGridSection: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(alignment: .leading, spacing: 12) {
            Label("Conditions", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            LazyVGrid(columns: columns, spacing: 12) {
                let dayData = selectedDayForecast
                if let sunrise = dayData.sunrise {
                    ConditionCell(icon: "sunrise.fill", iconColor: .orange, title: "Sunrise", value: formatTime(sunrise))
                }
                if let sunset = dayData.sunset {
                    ConditionCell(icon: "sunset.fill", iconColor: .orange, title: "Sunset", value: formatTime(sunset))
                }
                if let uv = dayData.uvIndex {
                    ConditionCell(icon: "sun.max.fill", iconColor: uvColor(for: uv), title: "UV Index",
                                  value: "\(Int(uv))", subtitle: uvDescription(for: uv))
                }
                if let humidity = dayData.humidity {
                    ConditionCell(icon: "humidity.fill", iconColor: .cyan, title: "Humidity",
                                  value: formatter.percentage(humidity))
                }
                if let wind = dayData.windSpeed {
                    ConditionCell(icon: "wind", iconColor: .gray, title: "Wind", value: formatter.wind(wind))
                }
                ConditionCell(
                    icon: "cloud.rain.fill",
                    iconColor: dayData.precipitationChance > 0.1 ? .blue : .secondary,
                    title: "Precipitation",
                    value: formatter.percentage(dayData.precipitationChance)
                )
                if let amount = dayData.precipitationAmount, amount > 0 {
                    ConditionCell(icon: "drop.fill", iconColor: .blue, title: "Expected",
                                  value: String(format: "%.1f mm", amount))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
        .padding(.horizontal)
    }

    // MARK: - Comparison Section (redesigned)

    private var comparisonSection: some View {
        VStack(spacing: 16) {
            conditionAgreementBanner
            sourceRowsCard
            temperatureRangeCard
        }
        .padding(.horizontal)
    }

    /// Banner showing how many sources agree on today's condition
    private var conditionAgreementBanner: some View {
        let (agreementText, icon, color) = conditionAgreementInfo
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(agreementText)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("\(availableSources.count) sources · \(formatter.date(forecast.date, timezone: forecast.timezone, style: .short))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var conditionAgreementInfo: (String, String, Color) {
        let conditions = availableSources.compactMap { source -> String? in
            dailyForecast(for: source)?.conditionDescription
        }
        guard !conditions.isEmpty else {
            return ("No data available", "questionmark.circle", .secondary)
        }
        let freq = Dictionary(grouping: conditions, by: { $0 }).mapValues { $0.count }
        let mostCommon = freq.max(by: { $0.value < $1.value })
        let agreeing = mostCommon?.value ?? 0
        let total = conditions.count

        if agreeing == total {
            return ("All \(total) sources agree", "checkmark.seal.fill", .green)
        } else if agreeing >= total - 1 {
            return ("\(agreeing) of \(total) agree: \(mostCommon?.key ?? "")", "checkmark.circle.fill", .orange)
        } else {
            return ("Sources split on conditions", "exclamationmark.triangle.fill", .red)
        }
    }

    /// Per-source rows showing all key metrics in one line per source
    private var sourceRowsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header label
            HStack {
                Text("Source Details")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("H° · L° · Rain · Wind")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider().padding(.horizontal, 16)

            ForEach(Array(availableSources.enumerated()), id: \.element) { idx, source in
                if let daily = dailyForecast(for: source) {
                    SourceDayRow(source: source, daily: daily, allHighs: allHighTemps)
                    if idx < availableSources.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private var allHighTemps: [Double] {
        availableSources.compactMap { dailyForecast(for: $0)?.highTemperatureFahrenheit }
    }

    /// Horizontal temperature range chart — each source as a bar showing its high/low range
    private var temperatureRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Temperature Range", systemImage: "thermometer.medium")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            let sourceData = availableSources.compactMap { source -> (WeatherSource, DailyForecast)? in
                guard let d = dailyForecast(for: source) else { return nil }
                return (source, d)
            }

            if !sourceData.isEmpty {
                Chart {
                    ForEach(sourceData, id: \.0) { source, daily in
                        BarMark(
                            xStart: .value("Low", daily.lowTemperatureFahrenheit),
                            xEnd: .value("High", daily.highTemperatureFahrenheit),
                            y: .value("Source", source.shortName)
                        )
                        .foregroundStyle(colorForSource(source).gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing, spacing: 4) {
                            Text("\(Int(daily.highTemperatureFahrenheit.rounded()))°")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.primary.opacity(0.1))
                        AxisValueLabel {
                            if let dbl = value.as(Double.self) {
                                Text("\(Int(dbl))°")
                                    .font(.system(.caption2, design: .rounded))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str)
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(sourceData.count) * 38)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    // MARK: - Helpers

    private func dailyForecast(for source: WeatherSource) -> DailyForecast? {
        guard let weather = weatherData.weather(from: source) else { return nil }
        return weather.daily.first { Calendar.current.isDate($0.date, inSameDayAs: forecast.date) }
    }

    private func colorForSource(_ source: WeatherSource) -> Color {
        switch source {
        case .weatherKit:    return .blue
        case .googleWeather: return .red
        case .noaa:          return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO:    return .purple
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = forecast.timezone
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func uvColor(for uv: Double) -> Color {
        switch uv {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }

    private func uvDescription(for uv: Double) -> String {
        switch uv {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }
}

// MARK: - Source Day Row

/// Compact row showing one source's daily forecast across all key metrics
private struct SourceDayRow: View {
    let source: WeatherSource
    let daily: DailyForecast
    let allHighs: [Double]  // for outlier detection

    private var sourceColor: Color {
        switch source {
        case .weatherKit:    return .blue
        case .googleWeather: return .red
        case .noaa:          return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO:    return .purple
        }
    }

    private var isOutlier: Bool {
        guard allHighs.count >= 3 else { return false }
        let sorted = allHighs.sorted()
        let median = sorted[sorted.count / 2]
        return abs(daily.highTemperatureFahrenheit - median) >= 5
    }

    var body: some View {
        HStack(spacing: 10) {
            // Source color accent
            Rectangle()
                .fill(sourceColor)
                .frame(width: 3)
                .clipShape(Capsule())
                .padding(.vertical, 4)

            // Source name
            HStack(spacing: 3) {
                Text(source.shortName)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(sourceColor)
                if isOutlier {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 52, alignment: .leading)

            // Condition icon
            WeatherIconView(condition: daily.condition, size: 18)

            Spacer()

            // High / Low
            HStack(spacing: 2) {
                Text("\(Int(daily.highTemperatureFahrenheit.rounded()))°")
                    .fontWeight(.semibold)
                Text("/")
                    .foregroundStyle(.tertiary)
                Text("\(Int(daily.lowTemperatureFahrenheit.rounded()))°")
                    .foregroundStyle(.secondary)
            }
            .font(.system(.subheadline, design: .rounded))

            // Precip
            Label("\(daily.precipitationPercentage)%", systemImage: "drop.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(daily.precipitationChance > 0.05 ? Color.blue : Color.secondary)
                .frame(width: 44, alignment: .trailing)

            // Wind
            if let wind = daily.windSpeed {
                Text("\(Int((wind * 2.237).rounded())) mph")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Reused Sub-views (unchanged from original)

struct DailyHourCell: View {
    let hour: HourlyForecast
    let timezone: TimeZone
    var isCurrentHour: Bool = false
    var sunrise: Date? = nil
    var sunset: Date? = nil

    private let formatter = WeatherFormatter.shared

    private var isNight: Bool {
        guard let sunrise = sunrise, let sunset = sunset else { return false }
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let hourComponents = calendar.dateComponents([.hour, .minute], from: hour.timestamp)
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise)
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset)
        guard let hourMinutes = hourComponents.hour.map({ $0 * 60 + (hourComponents.minute ?? 0) }),
              let sunriseMinutes = sunriseComponents.hour.map({ $0 * 60 + (sunriseComponents.minute ?? 0) }),
              let sunsetMinutes = sunsetComponents.hour.map({ $0 * 60 + (sunsetComponents.minute ?? 0) }) else {
            return false
        }
        return hourMinutes < sunriseMinutes || hourMinutes >= sunsetMinutes
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            WeatherIconView(condition: hour.condition, size: 24, isNight: isNight)
            Text(formatter.temperature(hour.temperature))
                .font(.subheadline)
                .fontWeight(.semibold)
            if hour.precipitationChance > 0 {
                Text(formatter.percentage(hour.precipitationChance))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            } else {
                Text(" ").font(.caption2)
            }
            if let wind = hour.windSpeed {
                Text(formatter.wind(wind))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56)
        .padding(.vertical, 8)
        .background(
            isCurrentHour
                ? LinearGradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.timeZone = timezone
        f.dateFormat = "ha"
        return f.string(from: hour.timestamp).lowercased()
    }
}

struct SunEventCell: View {
    let isSunrise: Bool
    let time: Date
    let timezone: TimeZone

    var body: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
            Image(systemName: isSunrise ? "sunrise.fill" : "sunset.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
            Text(isSunrise ? "Sunrise" : "Sunset")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            Text(" ").font(.caption2)
            Text(" ").font(.caption2)
        }
        .frame(width: 56)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.timeZone = timezone
        f.dateFormat = "h:mm"
        return f.string(from: time)
    }
}

struct ConditionCell: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

struct ComparisonChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

struct SourcePickerButton: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(isSelected ? .regular.interactive() : .regular)
            .foregroundStyle(isSelected ? Color.primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DailyDetailView(
        forecasts: [
            DailyForecast(
                date: Date(),
                highTemperature: 24,
                lowTemperature: 15,
                condition: .partlyCloudy,
                conditionDescription: "Partly Cloudy",
                precipitationChance: 0.2,
                sunrise: Calendar.current.date(bySettingHour: 7, minute: 15, second: 0, of: Date()),
                sunset: Calendar.current.date(bySettingHour: 17, minute: 45, second: 0, of: Date()),
                humidity: 0.65,
                windSpeed: 5.2,
                uvIndex: 6
            ),
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                highTemperature: 22,
                lowTemperature: 13,
                condition: .rain,
                conditionDescription: "Rain",
                precipitationChance: 0.8
            )
        ],
        initialIndex: 0,
        weatherData: WeatherData(
            location: Location(name: "San Francisco", coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)),
            sources: [:]
        )
    )
}
