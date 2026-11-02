import Foundation

/// A guarded app open: a pass, from the minute it started until its end.
public struct GuardedSpan: Hashable, Sendable, Codable {
    public var passID: UUID
    public var startedAt: Date
    public var until: Date

    public init(passID: UUID, startedAt: Date, until: Date) {
        self.passID = passID
        self.startedAt = startedAt
        self.until = until
    }
}

/// The counters of one local day. The breath's count resets at local
/// midnight.
public struct GameDay: Hashable, Sendable, Codable {
    public var day: LocalDay
    /// Whether Pofu observed any minute of the day: a tended day once it
    /// ends.
    public var observed: Bool
    /// Guarded minutes from passes (the pre-membership estimate).
    public var estimatedGuardedMinutes: Int
    /// Guarded minutes DeviceActivity measured, at least.
    public var measuredGuardedMinutes: Int
    /// Opens past the daily hour.
    public var overLimitOpens: Int
    /// Seeds Pofu gathered from quiet blocks, for the daily cap.
    public var gatheredSeeds: Energy

    public init(day: LocalDay) {
        self.day = day
        self.observed = false
        self.estimatedGuardedMinutes = 0
        self.measuredGuardedMinutes = 0
        self.overLimitOpens = 0
        self.gatheredSeeds = .zero
    }

    /// Today's guarded time for the breath: the measurement when there is
    /// one, never less than the passes say (it errs toward care).
    public var guardedMinutes: Int {
        max(estimatedGuardedMinutes, measuredGuardedMinutes)
    }
}

/// Everything the game model remembers: Pofu's wellbeing, calm, the
/// stations and seeds, and what Pofu has observed. Plain data; every change
/// goes through `WorldClock`, so the setters are internal to PofuCore and
/// `PofuWorld` only reads it.
///
/// The state advances on a grid of whole minutes (`clock`); see
/// `WorldClock` for why.
public struct GameState: Hashable, Sendable {
    /// The minute the model has advanced to; `nil` before the first
    /// advance.
    public internal(set) var clock: Date?
    /// The latest sign of life from the automation or the shield.
    public internal(set) var lastSignalAt: Date?
    /// A pass expired while nothing could close the guarded app (the soft
    /// gate): the time until the next sign of life is unobserved.
    public internal(set) var awaitingReturn: Bool
    /// Guarded apps open now.
    public internal(set) var guarded: [GuardedSpan]
    /// When the current Pofu foreground session began.
    public internal(set) var foregroundSince: Date?
    /// Opens within the care escalation window.
    public internal(set) var recentOpens: [Date]
    /// Today's counters.
    public internal(set) var today: GameDay?
    /// Whether the bedtime window in progress is still a calm night:
    /// `nil` outside one, or when Pofu did not see it begin.
    public internal(set) var calmNightCandidate: Bool?
    /// Days Pofu observed, cumulative (never "in a row", A4).
    public internal(set) var tendedDays: Int
    /// Calm nights, cumulative.
    public internal(set) var calmNights: Int
    /// Continuous quiet waking minutes toward Pofu's next gathered seed.
    public internal(set) var quietRunMinutes: Int
    public internal(set) var care: CareLedger
    public internal(set) var calm: CalmAccrual
    public internal(set) var stations: StationLedger

    public init(rules: GameRules = GameRules()) {
        self.clock = nil
        self.lastSignalAt = nil
        self.awaitingReturn = false
        self.guarded = []
        self.foregroundSince = nil
        self.recentOpens = []
        self.today = nil
        self.calmNightCandidate = nil
        self.tendedDays = 0
        self.calmNights = 0
        self.quietRunMinutes = 0
        self.care = CareLedger(rules: rules.care)
        self.calm = CalmAccrual(rules: rules.calm)
        self.stations = StationLedger(catalog: rules.catalog)
    }

    /// Whether a guarded app is open at the clock.
    public var isInGuardedApp: Bool {
        !guarded.isEmpty
    }
}

/// Why a saved game state could not be read.
public enum GameStateError: Error, Hashable, Sendable {
    /// Written by a newer build; leave it for an updated app.
    case unsupportedVersion(Int)
}

extension GameState: Codable {
    /// The format this build writes and the newest it reads.
    public static let currentVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version, clock, lastSignalAt, awaitingReturn, guarded, foregroundSince, recentOpens, today
        case calmNightCandidate, tendedDays, calmNights, quietRunMinutes, care, calm, stations
    }

    /// A state from a newer build fails with `unsupportedVersion`; any
    /// field missing from an older one takes its fresh value.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version <= Self.currentVersion else {
            throw GameStateError.unsupportedVersion(version)
        }
        self.init()
        clock = try container.decodeIfPresent(Date.self, forKey: .clock)
        lastSignalAt = try container.decodeIfPresent(Date.self, forKey: .lastSignalAt)
        awaitingReturn = try container.decodeIfPresent(Bool.self, forKey: .awaitingReturn) ?? false
        guarded = try container.decodeIfPresent([GuardedSpan].self, forKey: .guarded) ?? []
        foregroundSince = try container.decodeIfPresent(Date.self, forKey: .foregroundSince)
        recentOpens = try container.decodeIfPresent([Date].self, forKey: .recentOpens) ?? []
        today = try container.decodeIfPresent(GameDay.self, forKey: .today)
        calmNightCandidate = try container.decodeIfPresent(Bool.self, forKey: .calmNightCandidate)
        tendedDays = max(0, try container.decodeIfPresent(Int.self, forKey: .tendedDays) ?? 0)
        calmNights = max(0, try container.decodeIfPresent(Int.self, forKey: .calmNights) ?? 0)
        quietRunMinutes = max(0, try container.decodeIfPresent(Int.self, forKey: .quietRunMinutes) ?? 0)
        care = try container.decodeIfPresent(CareLedger.self, forKey: .care) ?? care
        calm = try container.decodeIfPresent(CalmAccrual.self, forKey: .calm) ?? calm
        stations = try container.decodeIfPresent(StationLedger.self, forKey: .stations) ?? stations
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encodeIfPresent(clock, forKey: .clock)
        try container.encodeIfPresent(lastSignalAt, forKey: .lastSignalAt)
        try container.encode(awaitingReturn, forKey: .awaitingReturn)
        try container.encode(guarded, forKey: .guarded)
        try container.encodeIfPresent(foregroundSince, forKey: .foregroundSince)
        try container.encode(recentOpens, forKey: .recentOpens)
        try container.encodeIfPresent(today, forKey: .today)
        try container.encodeIfPresent(calmNightCandidate, forKey: .calmNightCandidate)
        try container.encode(tendedDays, forKey: .tendedDays)
        try container.encode(calmNights, forKey: .calmNights)
        try container.encode(quietRunMinutes, forKey: .quietRunMinutes)
        try container.encode(care, forKey: .care)
        try container.encode(calm, forKey: .calm)
        try container.encode(stations, forKey: .stations)
    }
}

/// What one advance did, for the visit's "while you were away" and for
/// tests. Minutes count the minute grid.
public struct WorldDelta: Hashable, Sendable {
    public var stationSeeds: Energy = .zero
    public var gatheredSeeds: Energy = .zero
    public var sleepBonusSeeds: Energy = .zero
    public var skipSeeds: Energy = .zero
    /// Minutes the user was away and Pofu observed it: the world grew.
    public var awayMinutes = 0
    /// Minutes in a guarded app (as far as passes tell).
    public var guardedMinutes = 0
    /// Minutes past A20's grace in Pofu's foreground: paused.
    public var pausedMinutes = 0
    /// Minutes Pofu could not see: after an expiry until the next sign of
    /// life, past the observation window, or before setup.
    public var unobservedMinutes = 0
    public var calmSteps = 0
    public var calmResets = 0
    public var calmHalvings = 0
    public var calmNights = 0
    public var opens = 0
    public var resisted = 0
    public var arrivals: [IslandID] = []

    public init() {}

    /// Every seed credited.
    public var seeds: Energy {
        stationSeeds + gatheredSeeds + sleepBonusSeeds + skipSeeds
    }

    public static func += (lhs: inout WorldDelta, rhs: WorldDelta) {
        lhs.stationSeeds += rhs.stationSeeds
        lhs.gatheredSeeds += rhs.gatheredSeeds
        lhs.sleepBonusSeeds += rhs.sleepBonusSeeds
        lhs.skipSeeds += rhs.skipSeeds
        lhs.awayMinutes += rhs.awayMinutes
        lhs.guardedMinutes += rhs.guardedMinutes
        lhs.pausedMinutes += rhs.pausedMinutes
        lhs.unobservedMinutes += rhs.unobservedMinutes
        lhs.calmSteps += rhs.calmSteps
        lhs.calmResets += rhs.calmResets
        lhs.calmHalvings += rhs.calmHalvings
        lhs.calmNights += rhs.calmNights
        lhs.opens += rhs.opens
        lhs.resisted += rhs.resisted
        lhs.arrivals += rhs.arrivals
    }
}

/// What the world is doing at a minute.
public enum WorldActivity: String, Hashable, Sendable, Codable {
    /// Pofu has not heard a sign of life yet.
    case notSetUp
    /// Away and observed: the world grows.
    case away
    /// A guarded app is open: the stations pause, calm does not grow.
    case inGuardedApp
    /// Looking at Pofu past the grace (A20): the world waits.
    case paused
    /// Pofu cannot see: nothing that rewards absence accrues.
    case unobserved
}

/// One station as the world shows it.
public struct StationStatus: Hashable, Sendable, Identifiable {
    public var id: StationID
    public var island: IslandID
    public var level: Int
    public var maxLevel: Int
    public var isOpen: Bool
    /// The next level's cost; `nil` at the top.
    public var nextCost: Energy?
    /// The jar covers the next level.
    public var canAfford: Bool
    /// Seeds an hour at its level, before calm.
    public var seedsPerHour: Double
}

/// The world as `PofuWorld` reads it: a value computed from the state,
/// never a way to change it.
public struct WorldSnapshot: Hashable, Sendable {
    public var clock: Date?
    public var activity: WorldActivity
    public var isBedtime: Bool
    public var wellbeing: Double
    public var band: WellbeingBand
    public var calm: Double
    /// The calm ring's fill toward the next +0.1; 1 when full.
    public var calmProgress: Double
    public var calmIsFull: Bool
    public var pending: SeedPouch
    public var jar: Energy
    /// Seeds wait but cannot be collected while Pofu is not observing
    /// (ADR-0014's held seeds).
    public var isHolding: Bool
    public var tendedDays: Int
    public var calmNights: Int
    public var homeStage: Int
    /// The islands that arrived, in arrival order.
    public var islands: [IslandID]
    public var stations: [StationStatus]
    /// Seeds an hour right now: every station × calm × care, zero unless
    /// the user is away.
    public var seedsPerHour: Double
    public var guardedMinutesToday: Int
    public var dailyHourMinutes: Int
    public var overLimitOpensToday: Int
    /// The breath the next open would need.
    public var nextBreath: BreathRequirement?
}
