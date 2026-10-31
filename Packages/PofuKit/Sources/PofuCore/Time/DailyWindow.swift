import Foundation

/// A wall-clock time of day with minute precision, such as 23:00.
public struct LocalTime: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    /// Creates a time of day. Out-of-range values are clamped to
    /// `0...23` and `0...59` so that a malformed configuration can never
    /// crash the app.
    public init(hour: Int, minute: Int = 0) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    /// Minutes elapsed since local midnight, in `0..<1440`.
    public var minutesSinceMidnight: Int {
        hour * 60 + minute
    }

    public static func < (lhs: LocalTime, rhs: LocalTime) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }

    public var description: String {
        let hh = hour < 10 ? "0\(hour)" : "\(hour)"
        let mm = minute < 10 ? "0\(minute)" : "\(minute)"
        return "\(hh):\(mm)"
    }

    private enum CodingKeys: String, CodingKey {
        case hour
        case minute
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            hour: try container.decode(Int.self, forKey: .hour),
            minute: try container.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hour, forKey: .hour)
        try container.encode(minute, forKey: .minute)
    }
}

/// A recurring daily window of local time, such as bedtime from 23:00 to
/// 06:00.
///
/// The start is inclusive and the end is exclusive. A window whose end is
/// earlier than its start crosses midnight. A window whose start equals its
/// end is empty, which is how a window is switched off.
public struct DailyWindow: Hashable, Sendable, Codable {
    public var start: LocalTime
    public var end: LocalTime

    public init(start: LocalTime, end: LocalTime) {
        self.start = start
        self.end = end
    }

    /// Whether the window wraps past midnight into the next day.
    public var crossesMidnight: Bool {
        end < start
    }

    /// Whether the window never matches.
    public var isEmpty: Bool {
        start == end
    }

    /// The length of the window in minutes, in `0..<1440`.
    public var durationMinutes: Int {
        let length = end.minutesSinceMidnight - start.minutesSinceMidnight
        return length >= 0 ? length : length + 24 * 60
    }

    /// Whether the local time of `date`, in the time zone of `calendar`,
    /// falls inside the window.
    public func contains(_ date: Date, in calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return contains(minuteOfDay: minute)
    }

    /// Whether a minute of the day (`0..<1440`) falls inside the window.
    public func contains(minuteOfDay minute: Int) -> Bool {
        let start = start.minutesSinceMidnight
        let end = end.minutesSinceMidnight
        if start == end {
            return false
        }
        if start < end {
            return minute >= start && minute < end
        }
        return minute >= start || minute < end
    }
}
