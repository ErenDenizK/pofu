import Foundation

/// Which line the Door (Hop) asks under its title. The late-night line belongs to the hour the
/// screen shows, never to a flag read from the clock apart from it.
public enum HopQuestion: Equatable, Sendable {
    case late
    case oneBreath
    case quickCheckIn
    case intent

    /// Whether the Hop shows night: a bedtime session on a dark screen. Every Hop surface (the line,
    /// the skip outcome, the breath) reads this one rule, never the raw bedtime flag.
    public static func isNight(sessionIsBedtime: Bool, shownHourIsDark: Bool) -> Bool {
        sessionIsBedtime && shownHourIsDark
    }

    /// - Parameters:
    ///   - sessionIsBedtime: the Hop session was opened inside the bedtime window.
    ///   - shownHourIsDark: the hour the screen is painted for is night. Bedtime always paints night, so
    ///     a bedtime session on a night screen reads "late"; a midday screen never does.
    public static func choose(
        sessionIsBedtime: Bool,
        shownHourIsDark: Bool,
        rung: FrictionRung,
        isPastDailyHour: Bool
    ) -> HopQuestion {
        if isNight(sessionIsBedtime: sessionIsBedtime, shownHourIsDark: shownHourIsDark) { return .late }
        switch rung {
        case .pause: return isPastDailyHour ? .oneBreath : .quickCheckIn
        case .intent: return .intent
        }
    }
}
