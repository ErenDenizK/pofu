import Foundation

/// A jump of Rehearsal mode's clock. Rehearsal mode simulates the Screen
/// Time system inside the app (the free build), and its time controls let
/// a day be felt in minutes. Never used by the live gate.
public enum RehearsalJump: String, Hashable, Sendable, CaseIterable {
    /// An hour with the phone down, away from Pofu: quiet time.
    case quietHour
    /// To the start of the next bedtime.
    case night
    /// To the end of the bedtime under way, or of the next one: morning.
    case morning
    /// To 09:00 next: the day skip, landing in full daylight rather than
    /// at the first light of bedtime's end.
    case nextDay
}

/// Where Rehearsal mode's time controls land, and what the game hears
/// about the jump.
///
/// A jump is time spent away from Pofu: the user puts the phone down and
/// comes back. That is what makes calm grow and seeds gather on the island;
/// with Pofu on screen the world would stay paused (A20).
public struct RehearsalTime: Hashable, Sendable {
    public static let quietHour: TimeInterval = 60 * 60

    /// Where the day skip lands: mid-morning, so the world is in daylight.
    public static let dayStart = LocalTime(hour: 9, minute: 0)

    public var bedtime: DailyWindow
    public var calendar: Calendar

    public init(bedtime: DailyWindow, calendar: Calendar) {
        self.bedtime = bedtime
        self.calendar = calendar
    }

    /// The night or morning control's jump at `date`: morning during
    /// bedtime, night otherwise.
    public func nightOrMorning(at date: Date) -> RehearsalJump {
        bedtime.contains(date, in: calendar) ? .morning : .night
    }

    /// Where `jump` lands from `date`: always later than `date`.
    public func destination(of jump: RehearsalJump, from date: Date) -> Date {
        switch jump {
        case .quietHour:
            return date.addingTimeInterval(Self.quietHour)
        case .night:
            return next(bedtime.start, after: date)
        case .morning:
            return next(bedtime.end, after: date)
        case .nextDay:
            return next(Self.dayStart, after: date)
        }
    }

    /// The first instant after `date` whose local time is `time`, on the
    /// minute.
    public func next(_ time: LocalTime, after date: Date) -> Date {
        let today = LocalDay(containing: date, in: calendar)
        for offset in 0...2 {
            guard
                let start = today.adding(days: offset).start(in: calendar),
                let candidate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: start)
            else { continue }
            if candidate > date {
                return candidate
            }
        }
        // Only a calendar that skips the wanted time three days in a row
        // gets here; a day later is the honest fallback.
        return date.addingTimeInterval(24 * 60 * 60)
    }

    /// The game events of putting the phone down at `leaving` and opening
    /// Pofu again at `returning`.
    public static func awayEvents(leaving: Date, returning: Date) -> [GameEvent] {
        [
            GameEvent(at: leaving, kind: .foregroundEnded),
            GameEvent(at: max(leaving, returning), kind: .foregroundBegan),
        ]
    }
}

/// Guarded minutes Rehearsal mode has simulated today, the stand-in for
/// what DeviceActivity counts on a device. Starts again each local day.
public struct RehearsalUsage: Hashable, Sendable, Codable {
    public var day: LocalDay?
    public var minutes: Int

    public init(day: LocalDay? = nil, minutes: Int = 0) {
        self.day = day
        self.minutes = minutes
    }

    /// Minutes simulated on `day`; zero on any other day.
    public func minutes(on day: LocalDay) -> Int {
        self.day == day ? minutes : 0
    }

    /// Adds `minutes` of use on `day`, starting over on a new day.
    ///
    /// - Returns: The day's total before and after.
    @discardableResult
    public mutating func add(_ minutes: Int, on day: LocalDay) -> (before: Int, after: Int) {
        let before = self.minutes(on: day)
        let after = before + max(0, minutes)
        self.day = day
        self.minutes = after
        return (before, after)
    }

    /// The ladder's steps crossed by going from `before` to `after` guarded
    /// minutes: what the monitor extension is told, one event per step.
    public static func stepsCrossed(from before: Int, to after: Int, steps: [Int]) -> [Int] {
        steps.filter { $0 > before && $0 <= after }.sorted()
    }
}
