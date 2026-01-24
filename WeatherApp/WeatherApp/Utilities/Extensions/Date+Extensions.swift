//
//  Date+Extensions.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

extension Date {
    /// Format as "Today", "Tomorrow", or day name
    var weatherDayLabel: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        }
    }

    /// Short day name (Mon, Tue, etc.)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Hour in 12-hour format
    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: self)
    }

    /// Time ago string (e.g., "5 minutes ago")
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
