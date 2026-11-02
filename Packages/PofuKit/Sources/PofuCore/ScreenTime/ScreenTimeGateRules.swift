import Foundation

/// Every tunable number of the Screen Time gate (gate v2), in one value.
///
/// The defaults are the ones in `docs/product/ux/gate-v2.md` and
/// `docs/product/economy.md` ("The Screen Time gate"). The daily hour is
/// also a user setting (`UserProfile.dailyHourMinutes`), which overrides
/// `dailyHourMinutes` here.
public struct ScreenTimeGateRules: Hashable, Sendable, Codable {
    /// The daily hours the user may choose, in minutes.
    public static let dailyHourRange = 15...180

    /// Guarded minutes a day after which every open starts with a breath
    /// (ADR-0015).
    public var dailyHourMinutes: Int
    /// The DeviceActivity measuring step, in minutes.
    public var usageStepMinutes: Int
    /// How long the shield's quick check ("Just 3 minutes") lifts it.
    public var quickCheckMinutes: Int
    /// A quick check is not offered again until this long after the last
    /// one ended (the chain rule).
    public var quickCheckChainInterval: TimeInterval
    /// How long "Open with Pofu" waits for Pofu: the notification's
    /// lifetime and the window in which opening Pofu by hand starts Hop!.
    /// A request older than this was abandoned, which counts as resisted.
    public var openRequestLifetime: TimeInterval
    /// A shield left without any tap counts as resisted once this long
    /// has passed with nothing else happening (a silent leave).
    public var silentLeaveDelay: TimeInterval
    /// Shields shown for the same app within this window are one reach
    /// (the system re-renders the shield, for example from the switcher).
    public var reachDeduplicationWindow: TimeInterval
    /// A shield within this long of a Hop! for the same app is the same
    /// reach, counted once by Hop!.
    public var softGateOverlapWindow: TimeInterval
    /// The returning shield speaks of the pass that just ended for this
    /// long after its end.
    public var passEndedWindow: TimeInterval
    /// From this over-limit open of the day on, the breath is long.
    public var longBreathFromOpen: Int
    /// The short and long breath, in seconds, as the shield announces it.
    public var shortBreathSeconds: Int
    public var longBreathSeconds: Int
    /// Jealous lines on the shield per day, at most (game design §12).
    public var jealousLinesPerDay: Int

    public init(
        dailyHourMinutes: Int = 60,
        usageStepMinutes: Int = 15,
        quickCheckMinutes: Int = 3,
        quickCheckChainInterval: TimeInterval = 20 * 60,
        openRequestLifetime: TimeInterval = 10 * 60,
        silentLeaveDelay: TimeInterval = 60,
        reachDeduplicationWindow: TimeInterval = 10,
        softGateOverlapWindow: TimeInterval = 5,
        passEndedWindow: TimeInterval = 2 * 60,
        longBreathFromOpen: Int = 4,
        shortBreathSeconds: Int = 5,
        longBreathSeconds: Int = 10,
        jealousLinesPerDay: Int = 3
    ) {
        self.dailyHourMinutes = dailyHourMinutes
        self.usageStepMinutes = usageStepMinutes
        self.quickCheckMinutes = quickCheckMinutes
        self.quickCheckChainInterval = quickCheckChainInterval
        self.openRequestLifetime = openRequestLifetime
        self.silentLeaveDelay = silentLeaveDelay
        self.reachDeduplicationWindow = reachDeduplicationWindow
        self.softGateOverlapWindow = softGateOverlapWindow
        self.passEndedWindow = passEndedWindow
        self.longBreathFromOpen = longBreathFromOpen
        self.shortBreathSeconds = shortBreathSeconds
        self.longBreathSeconds = longBreathSeconds
        self.jealousLinesPerDay = jealousLinesPerDay
    }

    /// The default rules.
    public static let standard = ScreenTimeGateRules()

    /// These rules with the user's daily hour, clamped to the allowed
    /// range; `nil` keeps the default.
    public func withDailyHour(_ minutes: Int?) -> ScreenTimeGateRules {
        guard let minutes else { return self }
        var rules = self
        rules.dailyHourMinutes = Self.clampedDailyHour(minutes)
        return rules
    }

    /// `minutes` inside `dailyHourRange`.
    public static func clampedDailyHour(_ minutes: Int) -> Int {
        min(max(minutes, dailyHourRange.lowerBound), dailyHourRange.upperBound)
    }

    /// The measuring ladder for these rules: every step up to the daily
    /// hour, and the daily hour itself.
    public var ladder: GuardedUsageLadder {
        GuardedUsageLadder(dailyHourMinutes: dailyHourMinutes, stepMinutes: usageStepMinutes)
    }

    /// The breath for the `ordinal`th over-limit open today (1-based), in
    /// seconds.
    public func breathSeconds(forOverLimitOpen ordinal: Int) -> Int {
        ordinal >= longBreathFromOpen ? longBreathSeconds : shortBreathSeconds
    }
}
