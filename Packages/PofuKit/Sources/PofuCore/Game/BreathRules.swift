import Foundation

/// The breathing break, the hard limit (ADR-0015 and its v2 amendment;
/// game design §5, "The breathing break").
///
/// Past the daily hour of guarded time, every open first offers one breath
/// with Pofu that the user starts with a tap: 5 s for the 1st to 3rd
/// over-limit open of the day, 10 s from the 4th, and **never more than
/// `capSeconds`**, whatever the configuration says. Until friend approval
/// ships, the fourth rapid reach falls back to the breath (ADR-0015,
/// amendment of 2026-11-01). The emergency pass is never breathed. Seeds
/// play no part in any of it (A13).
public struct BreathRules: Hashable, Sendable, Codable {
    /// No breath is ever longer than this, in seconds (A14).
    public static let capSeconds = 10

    /// Guarded minutes a day after which every open starts with a breath.
    public var dailyHourMinutes: Int
    public var shortSeconds: Int
    public var longSeconds: Int
    /// From this over-limit open of the day on, the breath is long.
    public var longFromOpen: Int

    public init(dailyHourMinutes: Int = 60, shortSeconds: Int = 5, longSeconds: Int = 10, longFromOpen: Int = 4) {
        self.dailyHourMinutes = dailyHourMinutes
        self.shortSeconds = shortSeconds
        self.longSeconds = longSeconds
        self.longFromOpen = longFromOpen
    }

    /// The breath the gate's rules describe, with the user's daily hour
    /// already applied to them (`ScreenTimeGateRules.withDailyHour`).
    public init(gate: ScreenTimeGateRules) {
        self.init(
            dailyHourMinutes: gate.dailyHourMinutes,
            shortSeconds: gate.shortBreathSeconds,
            longSeconds: gate.longBreathSeconds,
            longFromOpen: gate.longBreathFromOpen
        )
    }

    /// Whether `guardedMinutes` today reaches the daily hour.
    public func isPastDailyHour(guardedMinutes: Int) -> Bool {
        guardedMinutes >= dailyHourMinutes
    }

    /// The breath for the `ordinal`th over-limit open today (from 1), in
    /// seconds: at least 1, at most `capSeconds`.
    public func seconds(forOverLimitOpen ordinal: Int) -> Int {
        Self.capped(ordinal >= longFromOpen ? longSeconds : shortSeconds)
    }

    /// The breath the next open needs, or `nil` when it needs none.
    ///
    /// - Parameters:
    ///   - guardedMinutes: Today's guarded time: measured, or estimated
    ///     from passes before the membership (game design §6).
    ///   - overLimitOpensToday: Opens past the daily hour today so far.
    ///   - isRapidReachFallback: This is the fourth rapid reach, which
    ///     falls back to the breath until friend approval ships. It asks
    ///     for the long breath even under the daily hour.
    ///   - isEmergency: The emergency pass, which is never breathed.
    public func requirement(
        guardedMinutes: Int,
        overLimitOpensToday: Int,
        isRapidReachFallback: Bool = false,
        isEmergency: Bool = false
    ) -> BreathRequirement? {
        guard !isEmergency else { return nil }
        if isPastDailyHour(guardedMinutes: guardedMinutes) {
            let ordinal = max(0, overLimitOpensToday) + 1
            let length = self.seconds(forOverLimitOpen: ordinal)
            let deeper = isRapidReachFallback ? max(length, Self.capped(longSeconds)) : length
            return BreathRequirement(reason: .dailyHour, seconds: deeper, overLimitOrdinal: ordinal)
        }
        if isRapidReachFallback {
            return BreathRequirement(reason: .rapidReach, seconds: Self.capped(longSeconds), overLimitOrdinal: nil)
        }
        return nil
    }

    private static func capped(_ seconds: Int) -> Int {
        min(max(seconds, 1), capSeconds)
    }
}

/// One breath the gate asks for before an open.
public struct BreathRequirement: Hashable, Sendable, Codable {
    public enum Reason: String, Hashable, Sendable, Codable {
        /// Today's guarded time reached the daily hour.
        case dailyHour
        /// The fourth rapid reach, until friend approval ships.
        case rapidReach
    }

    public var reason: Reason
    /// The breath's length, in seconds: never more than
    /// `BreathRules.capSeconds`.
    public var seconds: Int
    /// Which over-limit open of the day this is, from 1; `nil` under the
    /// daily hour.
    public var overLimitOrdinal: Int?

    public init(reason: Reason, seconds: Int, overLimitOrdinal: Int?) {
        self.reason = reason
        self.seconds = min(max(seconds, 1), BreathRules.capSeconds)
        self.overLimitOrdinal = overLimitOrdinal
    }

    /// The breath never starts by itself: the user taps "Breathe with Pofu".
    public var startsOnTap: Bool {
        true
    }

    /// The in-breath, in seconds: one breath with a long exhale, in : out =
    /// 2 : 3 (2 s and 3 s for 5 s; 4 s and 6 s for 10 s).
    public var inhaleSeconds: Double {
        Double(seconds) * 2 / 5
    }

    public var exhaleSeconds: Double {
        Double(seconds) * 3 / 5
    }
}

/// What the user did with a breathing break.
public enum BreathChoice: String, Hashable, Sendable, Codable, CaseIterable {
    /// "Not now" (*Şimdi değil*), before or during the breath.
    case notNow
    /// "I'm good, skip it" after the breath (the primary button).
    case skipAfterBreath
    /// "Open" after the breath.
    case open

    /// Whether the choice is a resisted reach: everything but opening.
    /// There is no way to open without breathing.
    public var countsAsSkip: Bool {
        self != .open
    }
}
