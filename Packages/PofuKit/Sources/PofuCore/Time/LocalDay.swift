import Foundation

/// A calendar day in the user's local time zone, such as 2026-10-31.
///
/// Day boundaries come from the time zone of the calendar passed in, so a
/// day always starts at local midnight. The year, month, and day labels are
/// always Gregorian, even when the user's calendar is not, so that ordering
/// and persistence never depend on locale settings.
public struct LocalDay: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The local day that contains `date`, using the time zone of `calendar`.
    public init(containing date: Date, in calendar: Calendar) {
        let gregorian =
            calendar.identifier == .gregorian ? calendar : LocalDay.gregorian(in: calendar.timeZone)
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        self.init(
            year: components.year ?? 0,
            month: components.month ?? 0,
            day: components.day ?? 0
        )
    }

    /// The local day `count` days after this one (negative for earlier days).
    public func adding(days count: Int) -> LocalDay {
        // Calendar arithmetic in UTC at noon is immune to DST transitions.
        let utc = LocalDay.gregorian(in: TimeZone(secondsFromGMT: 0) ?? .current)
        let noon = DateComponents(year: year, month: month, day: day, hour: 12)
        guard
            let date = utc.date(from: noon),
            let shifted = utc.date(byAdding: .day, value: count, to: date)
        else {
            return self
        }
        return LocalDay(containing: shifted, in: utc)
    }

    /// The instant this day starts (local midnight) in the time zone of
    /// `calendar`.
    public func start(in calendar: Calendar) -> Date? {
        let local = LocalDay.gregorian(in: calendar.timeZone)
        return local.date(from: DateComponents(year: year, month: month, day: day))
    }

    public static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public var description: String {
        "\(LocalDay.pad(year, to: 4))-\(LocalDay.pad(month, to: 2))-\(LocalDay.pad(day, to: 2))"
    }

    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func pad(_ value: Int, to width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
