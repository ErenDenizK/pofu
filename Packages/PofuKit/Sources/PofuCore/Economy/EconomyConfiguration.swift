import Foundation

/// Every tunable constant of Pofu's economy, in one value.
///
/// The defaults are the v0 rules documented in `docs/product/economy.md`.
/// The configuration is `Codable` so that it can be loaded from a file and
/// tuned without code changes, and so simulations can sweep alternatives.
public struct EconomyConfiguration: Hashable, Sendable, Codable {
    /// Energy granted once at the start of every local day the user is
    /// active, so nobody is ever stuck at zero.
    public var dailyAllowance: Energy
    public var earning: EarningRules
    public var spending: SpendingRules
    public var friction: FrictionRules
    public var vitality: VitalityRules
    /// How staying away from guarded apps earns seeds (ADR-0014).
    public var quietTime: QuietTimeRules

    public init(
        dailyAllowance: Energy = 15,
        earning: EarningRules = EarningRules(),
        spending: SpendingRules = SpendingRules(),
        friction: FrictionRules = FrictionRules(),
        vitality: VitalityRules = VitalityRules(),
        quietTime: QuietTimeRules = QuietTimeRules()
    ) {
        self.dailyAllowance = dailyAllowance
        self.earning = earning
        self.spending = spending
        self.friction = friction
        self.vitality = vitality
        self.quietTime = quietTime
    }

    /// The v0 rules.
    public static let standard = EconomyConfiguration()

    private enum CodingKeys: String, CodingKey {
        case dailyAllowance, earning, spending, friction, vitality, quietTime
    }

    /// Sections added after v0 are optional on decode, so a configuration
    /// file written before them still loads with their defaults.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            dailyAllowance: try container.decode(Energy.self, forKey: .dailyAllowance),
            earning: try container.decode(EarningRules.self, forKey: .earning),
            spending: try container.decode(SpendingRules.self, forKey: .spending),
            friction: try container.decode(FrictionRules.self, forKey: .friction),
            vitality: try container.decode(VitalityRules.self, forKey: .vitality),
            quietTime: try container.decodeIfPresent(QuietTimeRules.self, forKey: .quietTime) ?? QuietTimeRules()
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dailyAllowance, forKey: .dailyAllowance)
        try container.encode(earning, forKey: .earning)
        try container.encode(spending, forKey: .spending)
        try container.encode(friction, forKey: .friction)
        try container.encode(vitality, forKey: .vitality)
        try container.encode(quietTime, forKey: .quietTime)
    }
}

/// How activities turn into energy.
public struct EarningRules: Hashable, Sendable, Codable {
    /// Energy per whole minute of activity before multipliers (v0: 1 per 2
    /// minutes).
    public var energyPerMinute: Double
    /// Multiplier for activities verified passively, structurally, or
    /// actively (ADR-0004).
    public var verifiedMultiplier: Double
    /// The most energy honor-system (self-reported) activities can earn per
    /// local day. Earnings past the cap are forfeited and reported.
    public var honorDailyCap: Energy
    /// Steps per energy unit for passively counted steps.
    public var stepsPerEnergy: Int

    public init(
        energyPerMinute: Double = 0.5,
        verifiedMultiplier: Double = 1.5,
        honorDailyCap: Energy = 120,
        stepsPerEnergy: Int = 500
    ) {
        self.energyPerMinute = energyPerMinute
        self.verifiedMultiplier = verifiedMultiplier
        self.honorDailyCap = honorDailyCap
        self.stepsPerEnergy = stepsPerEnergy
    }
}

/// How unlock windows are priced.
public struct SpendingRules: Hashable, Sendable, Codable {
    /// The unlock window lengths on offer, in minutes.
    public var unlockDurations: [Int]
    /// Price per minute of unlock before multipliers.
    public var pricePerMinute: Energy
    /// Each earlier paid unlock inside the escalation window multiplies the
    /// price by this factor, compounding.
    public var escalationMultiplier: Double
    /// The rolling window, in seconds, in which paid unlocks escalate the
    /// price.
    public var escalationWindow: TimeInterval
    /// Price multiplier inside the bedtime window.
    public var nightMultiplier: Double
    /// The local-time window in which night pricing applies.
    public var bedtime: DailyWindow

    public init(
        unlockDurations: [Int] = [5, 10, 15, 30],
        pricePerMinute: Energy = 1,
        escalationMultiplier: Double = 1.25,
        escalationWindow: TimeInterval = 3 * 60 * 60,
        nightMultiplier: Double = 2,
        bedtime: DailyWindow = DailyWindow(
            start: LocalTime(hour: 23),
            end: LocalTime(hour: 6)
        )
    ) {
        self.unlockDurations = unlockDurations
        self.pricePerMinute = pricePerMinute
        self.escalationMultiplier = escalationMultiplier
        self.escalationWindow = escalationWindow
        self.nightMultiplier = nightMultiplier
        self.bedtime = bedtime
    }
}

/// How the friction ladder climbs and resets.
public struct FrictionRules: Hashable, Sendable, Codable {
    /// An attempt less than this many seconds after the previous attempt
    /// climbs one rung; a longer gap resets the ladder to `pause`.
    public var cooldown: TimeInterval
    /// The highest rung that repeated attempts alone can reach. `askFriend`
    /// is otherwise reserved for when the balance cannot cover an unlock.
    public var highestAttemptRung: FrictionRung
    /// Length, in minutes, of the pass granted when the user proceeds on a
    /// free rung (`pause` or `intent`).
    public var freePassMinutes: Int
    /// Length, in minutes, of the free emergency pass offered once per
    /// local day on the `pay` and `askFriend` rungs. Zero switches it off.
    public var emergencyPassMinutes: Int

    public init(
        cooldown: TimeInterval = 60 * 60,
        highestAttemptRung: FrictionRung = .pay,
        freePassMinutes: Int = 5,
        emergencyPassMinutes: Int = 3
    ) {
        self.cooldown = cooldown
        self.highestAttemptRung = highestAttemptRung
        self.freePassMinutes = freePassMinutes
        self.emergencyPassMinutes = emergencyPassMinutes
    }
}

/// How the companion's vitality is derived. See `VitalityModel`.
public struct VitalityRules: Hashable, Sendable, Codable {
    /// Daily budget of distracting usage, in minutes.
    public var dailyBudgetMinutes: Double
    /// Usage, as a multiple of the budget, at which the usage score reaches
    /// zero. With 2, the score is 1 at no usage, 0.5 at the budget, and 0 at
    /// twice the budget.
    public var usageZeroAtBudgetMultiple: Double
    /// Earned activity energy at which the activity score reaches 0.5.
    public var activityHalfSaturation: Energy
    public var usageWeight: Double
    public var resistedWeight: Double
    public var activityWeight: Double
    /// Exponential moving average factor in `0...1`: the share of a new
    /// day's score that flows into vitality. Lower is steadier.
    public var smoothing: Double
    /// Vitality before any day has been observed.
    public var initialVitality: Double
    /// Lower bounds of the mood bands, from highest to lowest.
    public var thrivingThreshold: Double
    public var contentThreshold: Double
    public var tiredThreshold: Double

    public init(
        dailyBudgetMinutes: Double = 60,
        usageZeroAtBudgetMultiple: Double = 2,
        activityHalfSaturation: Energy = 30,
        usageWeight: Double = 0.5,
        resistedWeight: Double = 0.25,
        activityWeight: Double = 0.25,
        smoothing: Double = 0.3,
        initialVitality: Double = 0.6,
        thrivingThreshold: Double = 0.75,
        contentThreshold: Double = 0.5,
        tiredThreshold: Double = 0.25
    ) {
        self.dailyBudgetMinutes = dailyBudgetMinutes
        self.usageZeroAtBudgetMultiple = usageZeroAtBudgetMultiple
        self.activityHalfSaturation = activityHalfSaturation
        self.usageWeight = usageWeight
        self.resistedWeight = resistedWeight
        self.activityWeight = activityWeight
        self.smoothing = smoothing
        self.initialVitality = initialVitality
        self.thrivingThreshold = thrivingThreshold
        self.contentThreshold = contentThreshold
        self.tiredThreshold = tiredThreshold
    }
}

/// How time away from the guarded apps earns seeds (ADR-0014). The
/// bedtime window is the one in `SpendingRules`, so night means the same
/// thing everywhere.
public struct QuietTimeRules: Hashable, Sendable, Codable {
    /// Length, in minutes, of one block of continuous quiet waking time.
    /// Only whole blocks earn. Zero or less switches quiet earning off.
    public var blockMinutes: Int
    /// Seeds per whole block.
    public var seedsPerBlock: Energy
    /// The most quiet-block seeds one local day can earn. Separate from the
    /// honor cap; the slept-on-it bonus does not count toward it.
    public var dailyCap: Energy
    /// The one-time bonus for a whole bedtime window without an open.
    public var sleepBonus: Energy
    /// How long, in seconds, one sign of life from the automation (a
    /// check-in or a pass-through) keeps Pofu observing. Quiet time past
    /// it does not count, and seeds already in the cheeks are held until
    /// the next sign of life.
    public var observationWindow: TimeInterval

    public init(
        blockMinutes: Int = 10,
        seedsPerBlock: Energy = 1,
        dailyCap: Energy = 48,
        sleepBonus: Energy = 10,
        observationWindow: TimeInterval = 72 * 60 * 60
    ) {
        self.blockMinutes = blockMinutes
        self.seedsPerBlock = seedsPerBlock
        self.dailyCap = dailyCap
        self.sleepBonus = sleepBonus
        self.observationWindow = observationWindow
    }
}
