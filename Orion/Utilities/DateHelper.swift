// DateHelper.swift — Utilities

import Foundation

enum DateHelper {
    static let calendar = Calendar.current

    static func startOfDay(_ date: Date = .now) -> Date {
        calendar.startOfDay(for: date)
    }

    static func startOfWeek(for date: Date = .now, calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2  // Monday
        return cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    static func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    static func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }

    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Section header for History screen groups
    static func relativeSection(for date: Date) -> String {
        if isToday(date) { return "Today" }
        if isYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        if calendar.isDate(date, equalTo: .now, toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE" // "Monday"
        } else if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            formatter.dateFormat = "MMMM d" // "April 18"
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
        }
        return formatter.string(from: date)
    }

    /// Short time string e.g. "2:30 PM"
    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Short date string e.g. "Apr 18"
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Day number only "18"
    static func dayNumber(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    /// Days in the current month
    static func daysInCurrentMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: .now),
              let monthStart = calendar.dateInterval(of: .month, for: .now)?.start else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    /// Format duration in minutes to "Xh Ym" string
    static func formatDuration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    /// Format seconds to "MM:SS"
    static func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
