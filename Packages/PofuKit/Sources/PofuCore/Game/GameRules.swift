import Foundation

/// Pofu's wellbeing (*keyif*) rules: game design §5, "Pofu's wellbeing",
/// and ADR-0017 (Pofu never dies).
public struct CareRules: Hashable, Sendable, Codable {
    /// Wellbeing at the start.
    public var start: Double = 70
    /// Wellbeing never goes below this: Pofu is curled up, never gone.
    public var floor: Double = 5
    public var ceiling: Double = 100
    /// Drain per minute while a guarded app is open.
    public var drainPerMinute: Double = 0.35
    /// The drain multiplier inside the bedtime window.
    public var nightDrainMultiplier: Double = 2
    /// The drain multiplier per earlier open within `escalationWindow`.
    public var escalationPerEarlierOpen: Double = 1.25
    public var escalationWindow: TimeInterval = 3 * 60 * 60
    /// Drain for the reach itself, once per open.
    public var drainPerOpen: Double = 1.5
    /// Healing per hour of calm waking time from "tired" up. In the two
    /// lowest bands healing is band-relative instead, keeping ADR-0017's
    /// promise that one quiet hour lifts Pofu out of the bottom
    /// (`CareLedger.healMinute`).
    public var healPerCalmHour: Double = 5
    /// Healing for a calm night (no opens, observed throughout).
    public var calmNightHeal: Double = 10
    /// Healing per resisted reach, for at most `healedSkipsPerDay` a day.
    public var healPerSkip: Double = 1
    public var healedSkipsPerDay: Int = 6
    /// "Sleeps it off": each night, wellbeing below `recoveryTarget` moves
    /// `nightRecoveryShare` of the way back to it.
    public var recoveryTarget: Double = 60
    public var nightRecoveryShare: Double = 0.3
    /// Band thresholds (lower bounds).
    public var cozyFrom: Double = 75
    public var contentFrom: Double = 50
    public var tiredFrom: Double = 25
    public var unwellFrom: Double = 12
    /// Below `tiredFrom` the residents look after Pofu: production runs at
    /// this many tenths of its rate.
    public var unwellProductionTenths: Int = 6

    public init() {}
}

/// The calm multiplier (*huzur*) rules: game design §5, "The calm
/// multiplier". Calm is kept in tenths, so ×1.3 is 13.
public struct CalmRules: Hashable, Sendable, Codable {
    /// ×1.0.
    public var minimumTenths: Int = 10
    /// ×2.0.
    public var maximumTenths: Int = 20
    /// Continuous calm waking minutes per +0.1.
    public var stepMinutes: Int = 20
    /// A pass of at most this many minutes is a quick check: it halves the
    /// bonus instead of resetting it.
    public var quickCheckMinutes: Int = 3
    /// A quick check that starts less than this long after the previous
    /// quick check's end counts as a full open (the chain rule).
    public var quickCheckChain: TimeInterval = 20 * 60
    /// A calm night adds this many tenths.
    public var calmNightTenths: Int = 2

    public init() {}

    /// The quick-check part of the gate's rules, so the shield and the game
    /// agree on what a quick check is.
    public init(gate: ScreenTimeGateRules) {
        self.init()
        quickCheckMinutes = gate.quickCheckMinutes
        quickCheckChain = gate.quickCheckChainInterval
    }
}

/// Seeds as world material (ADR-0015): the capped thank-you for a resisted
/// reach. Pofu's quiet gathering keeps ADR-0014's `QuietTimeRules`; the
/// stations' rates live in the `ArchipelagoCatalog`.
public struct SeedRules: Hashable, Sendable, Codable {
    /// Seeds per resisted reach.
    public var skipGift: Energy = 3
    /// Resisted reaches a day that earn the gift.
    public var giftedSkipsPerDay: Int = 5

    public init() {}
}

/// What Pofu can see of guarded-app time (game design §6).
public enum GuardedMeasurement: String, Hashable, Sendable, Codable, CaseIterable {
    /// Pre-membership: the Shortcuts soft gate. Nothing closes the guarded
    /// app when a pass expires, so the time from an expiry to the next sign
    /// of life is unobserved, and a sign of life keeps Pofu observing only
    /// for the observation window.
    case softGate
    /// With the paid membership: the shield returns when a pass ends, so
    /// the time after a pass is observed, and Pofu keeps observing.
    case screenTime
}

/// Every rule of the game model in one value. The defaults are game design
/// v2's; tunable numbers live here, never in the code that applies them.
public struct GameRules: Hashable, Sendable, Codable {
    public var care: CareRules
    public var calm: CalmRules
    public var seeds: SeedRules
    /// Pofu's quiet gathering and observation (ADR-0014, unchanged).
    public var quiet: QuietTimeRules
    public var breath: BreathRules
    /// The islands sleep (A5) and calm holds in this window.
    public var bedtime: DailyWindow
    /// A20: the first this-long of a Pofu foreground session counts as
    /// away; past it, the world is paused while the user looks at it.
    public var foregroundGrace: TimeInterval
    public var measurement: GuardedMeasurement
    public var catalog: ArchipelagoCatalog
    /// Islands that arrive with an app update ("with a season") and have
    /// been released.
    public var releasedIslands: Set<IslandID>

    public init(
        care: CareRules = CareRules(),
        calm: CalmRules = CalmRules(),
        seeds: SeedRules = SeedRules(),
        quiet: QuietTimeRules = QuietTimeRules(),
        breath: BreathRules = BreathRules(),
        bedtime: DailyWindow = SpendingRules().bedtime,
        foregroundGrace: TimeInterval = 2 * 60,
        measurement: GuardedMeasurement = .softGate,
        catalog: ArchipelagoCatalog = .standard,
        releasedIslands: Set<IslandID> = []
    ) {
        self.care = care
        self.calm = calm
        self.seeds = seeds
        self.quiet = quiet
        self.breath = breath
        self.bedtime = bedtime
        self.foregroundGrace = foregroundGrace
        self.measurement = measurement
        self.catalog = catalog
        self.releasedIslands = releasedIslands
    }

    /// The game rules that match the gate's: the daily hour, the breath,
    /// and the quick check.
    public init(gate: ScreenTimeGateRules, measurement: GuardedMeasurement) {
        self.init(calm: CalmRules(gate: gate), breath: BreathRules(gate: gate), measurement: measurement)
    }
}
