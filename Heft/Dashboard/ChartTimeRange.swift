//
//  ChartTimeRange.swift
//  Heft
//
//  Shared time range model for Weight and BMI charts.
//

import SwiftUI

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1A"
    case threeMonths = "3A"
    case sixMonths = "6A"
    case oneYear = "1Y"
    case all = "Tümü"

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .oneMonth: return String(localized: "1A", comment: "1 Month chart range button")
        case .threeMonths: return String(localized: "3A", comment: "3 Months chart range button")
        case .sixMonths: return String(localized: "6A", comment: "6 Months chart range button")
        case .oneYear: return String(localized: "1Y", comment: "1 Year chart range button")
        case .all: return String(localized: "Tümü", comment: "All Time chart range button")
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .oneMonth: return String(localized: "1 Ay", comment: "1 Month chart range a11y title")
        case .threeMonths: return String(localized: "3 Ay", comment: "3 Months chart range a11y title")
        case .sixMonths: return String(localized: "6 Ay", comment: "6 Months chart range a11y title")
        case .oneYear: return String(localized: "1 Yıl", comment: "1 Year chart range a11y title")
        case .all: return String(localized: "Tüm Zamanlar", comment: "All Time chart range a11y title")
        }
    }

    var days: Int? {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return nil
        }
    }

    func isAvailable(for allDates: [Date]) -> Bool {
        guard let minDate = allDates.min(), let maxDate = allDates.max() else { return true }
        let spanDays = max(1, Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 1)
        switch self {
        case .oneMonth, .all:
            return true
        case .threeMonths:
            return spanDays >= 14
        case .sixMonths:
            return spanDays >= 60
        case .oneYear:
            return spanDays >= 120
        }
    }

    func dateRange(relativeTo referenceDate: Date, allDates: [Date]) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endOfToday = calendar.startOfDay(for: referenceDate).addingTimeInterval(86399)

        var start: Date
        let end: Date = endOfToday

        if let days = days {
            start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: referenceDate))
                ?? referenceDate.addingTimeInterval(-Double(days) * 86400)
        } else {
            if let earliest = allDates.min() {
                let earliestStart = calendar.startOfDay(for: earliest)
                let spanDays = calendar.dateComponents([.day], from: earliestStart, to: calendar.startOfDay(for: referenceDate)).day ?? 0
                if spanDays < 14 {
                    start = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: referenceDate))
                        ?? referenceDate.addingTimeInterval(-14 * 86400)
                } else {
                    start = earliestStart
                }
            } else {
                start = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: referenceDate))
                    ?? referenceDate.addingTimeInterval(-14 * 86400)
            }
        }

        let trailingBufferDays: Double
        let leadingBufferDays: Double
        switch self {
        case .oneMonth:
            trailingBufferDays = 2.5
            leadingBufferDays = 1.0
        case .threeMonths:
            trailingBufferDays = 5.0
            leadingBufferDays = 2.0
        case .sixMonths:
            trailingBufferDays = 8.0
            leadingBufferDays = 4.0
        case .oneYear:
            trailingBufferDays = 14.0
            leadingBufferDays = 7.0
        case .all:
            trailingBufferDays = 2.5
            leadingBufferDays = 1.0
        }

        let bufferedStart = start.addingTimeInterval(-leadingBufferDays * 86400)
        let bufferedEnd = end.addingTimeInterval(trailingBufferDays * 86400)
        let safeEnd = max(bufferedStart.addingTimeInterval(86400), bufferedEnd)
        return bufferedStart...safeEnd
    }

    private static var cachedFormattersLocaleId: String = ""
    private static var _dayMonthFormatter: DateFormatter = makeDayMonthFormatter()
    private static var _monthFormatter: DateFormatter = makeMonthFormatter()
    private static var _monthYearFormatter: DateFormatter = makeMonthYearFormatter()

    private static func updateFormattersIfNeeded() {
        let currentId = Locale.autoupdatingCurrent.identifier
        if cachedFormattersLocaleId != currentId {
            cachedFormattersLocaleId = currentId
            _dayMonthFormatter = makeDayMonthFormatter()
            _monthFormatter = makeMonthFormatter()
            _monthYearFormatter = makeMonthYearFormatter()
        }
    }

    private static func makeDayMonthFormatter() -> DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMM", options: 0, locale: loc)
        return df
    }

    private static func makeMonthFormatter() -> DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM", options: 0, locale: loc)
        return df
    }

    private static func makeMonthYearFormatter() -> DateFormatter {
        let df = DateFormatter()
        let loc = Locale.autoupdatingCurrent
        df.locale = loc
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMyy", options: 0, locale: loc)
        return df
    }

    private static var dayMonthFormatter: DateFormatter {
        updateFormattersIfNeeded()
        return _dayMonthFormatter
    }

    private static var monthFormatter: DateFormatter {
        updateFormattersIfNeeded()
        return _monthFormatter
    }

    private static var monthYearFormatter: DateFormatter {
        updateFormattersIfNeeded()
        return _monthYearFormatter
    }

    func filter(entries: [WeightEntry], relativeTo referenceDate: Date) -> [WeightEntry] {
        let isAlreadySorted = zip(entries, entries.dropFirst()).allSatisfy { $0.date <= $1.date }
        guard let days = days else {
            return isAlreadySorted ? entries : entries.sorted { $0.date < $1.date }
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate.addingTimeInterval(-Double(days) * 86400)
        let filtered = entries.filter { $0.date >= cutoff }
        return isAlreadySorted ? filtered : filtered.sorted { $0.date < $1.date }
    }

    func xAxisDates(referenceDate: Date, allDates: [Date]) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        switch self {
        case .oneMonth:
            let d1 = calendar.date(byAdding: .day, value: -20, to: today) ?? today.addingTimeInterval(-20 * 86400)
            let d2 = calendar.date(byAdding: .day, value: -10, to: today) ?? today.addingTimeInterval(-10 * 86400)
            return [d1, d2, today]

        case .threeMonths:
            let m2 = calendar.date(byAdding: .month, value: -2, to: today) ?? today.addingTimeInterval(-60 * 86400)
            let m1 = calendar.date(byAdding: .month, value: -1, to: today) ?? today.addingTimeInterval(-30 * 86400)
            return [m2, m1, today]

        case .sixMonths:
            let m5 = calendar.date(byAdding: .month, value: -5, to: today) ?? today.addingTimeInterval(-150 * 86400)
            let m3 = calendar.date(byAdding: .month, value: -3, to: today) ?? today.addingTimeInterval(-90 * 86400)
            let m1 = calendar.date(byAdding: .month, value: -1, to: today) ?? today.addingTimeInterval(-30 * 86400)
            return [m5, m3, m1, today]

        case .oneYear:
            let m9 = calendar.date(byAdding: .month, value: -9, to: today) ?? today.addingTimeInterval(-270 * 86400)
            let m6 = calendar.date(byAdding: .month, value: -6, to: today) ?? today.addingTimeInterval(-180 * 86400)
            let m3 = calendar.date(byAdding: .month, value: -3, to: today) ?? today.addingTimeInterval(-90 * 86400)
            return [m9, m6, m3, today]

        case .all:
            let earliest = allDates.min() ?? today.addingTimeInterval(-14 * 86400)
            let spanDays = max(14, calendar.dateComponents([.day], from: earliest, to: today).day ?? 14)

            if spanDays <= 30 {
                let d1 = calendar.date(byAdding: .day, value: -spanDays, to: today) ?? today.addingTimeInterval(-Double(spanDays) * 86400)
                let d2 = calendar.date(byAdding: .day, value: -(spanDays / 2), to: today) ?? today.addingTimeInterval(-Double(spanDays / 2) * 86400)
                return [d1, d2, today]
            } else if spanDays <= 90 {
                let d1 = calendar.date(byAdding: .day, value: -spanDays, to: today) ?? today.addingTimeInterval(-Double(spanDays) * 86400)
                let d2 = calendar.date(byAdding: .day, value: -(spanDays * 2 / 3), to: today) ?? today
                let d3 = calendar.date(byAdding: .day, value: -(spanDays / 3), to: today) ?? today
                return [d1, d2, d3, today]
            } else {
                let m3 = calendar.date(byAdding: .month, value: -max(1, spanDays / 90), to: today) ?? today
                let m2 = calendar.date(byAdding: .month, value: -max(2, spanDays * 2 / 90), to: today) ?? today
                let m1 = calendar.date(byAdding: .month, value: -max(3, spanDays / 30), to: today) ?? today
                return [m1, m2, m3, today]
            }
        }
    }

    func format(date: Date, relativeTo referenceDate: Date) -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: referenceDate)
        let dateYear = calendar.component(.year, from: date)

        switch self {
        case .oneMonth:
            return Self.dayMonthFormatter.string(from: date)

        case .threeMonths, .sixMonths, .oneYear:
            if dateYear != currentYear {
                return Self.monthYearFormatter.string(from: date)
            } else {
                return Self.monthFormatter.string(from: date)
            }

        case .all:
            let spanDays = calendar.dateComponents([.day], from: date, to: referenceDate).day ?? 1
            if spanDays <= 45 {
                return Self.dayMonthFormatter.string(from: date)
            } else if dateYear != currentYear {
                return Self.monthYearFormatter.string(from: date)
            } else {
                return Self.monthFormatter.string(from: date)
            }
        }
    }
}
