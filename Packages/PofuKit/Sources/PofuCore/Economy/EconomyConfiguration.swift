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

    public init(
        dailyAllowance: Energy = 15,
        earning: EarningRules = EarningRules(),
        spending: SpendingRules = SpendingRules(),
        friction: FrictionRules = FrictionRules(),
        vitality: VitalityRules = VitalityRules()
    ) {
        self.dailyAllowance = dailyAllowance
        self.earning = earning
        self.spending = spending
        self.friction = friction
        self.vitality = vitality
    }

    /// The v0 rules.
    public static let standard = EconomyConfiguration()
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

    public init(
        cooldown: TimeInterval = 60 * 60,
        highestAttemptRung: FrictionRung = .pay,
        freePassMinutes: Int = 5
    ) {
        self.cooldown = cooldown
        self.highestAttemptRung = highestAttemptRung
        self.freePassMinutes = freePassMinutes
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
