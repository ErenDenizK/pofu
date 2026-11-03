/// How island-game rounds are earned and played (archipelago system §4.2,
/// docs/product/minigames.md §4). Rounds are earned, never bought: a small
/// daily baseline so a heavy scroller still plays, one more per resisted
/// reach, and a hard cap on plays a day.
public struct RoundRules: Hashable, Sendable, Codable {
    /// Rounds everyone gets each day (behaviour changes how many, never
    /// whether).
    public var dailyBaseline: Int = 2
    /// Rounds a resisted reach earns.
    public var perResistedReach: Int = 1
    /// Resisted reaches that earn a round, per day.
    public var resistedReachesPerDay: Int = 6
    /// Rounds that can be played per day, banked or not (A22).
    public var playsPerDay: Int = 12
    /// The most seeds one round can credit (`PofuGames.SeedYield`).
    public var maximumYield: Int = 5

    public init() {}
}

/// Why a round could not be played.
public enum RoundError: Error, Hashable, Sendable {
    /// No earned round is banked.
    case noRoundBanked
    /// Today's plays are used up; banked rounds wait for tomorrow.
    case dailyLimitReached
    /// No rounds at night (A21).
    case islandsAsleep
}

/// Earned rounds, banked, and today's plays.
///
/// Rounds never expire (A2): unplayed ones stay banked, but at most
/// `playsPerDay` are played a day. The baseline is granted lazily, the
/// first time a day is seen, so a day Pofu never hears about still counts.
public struct RoundLedger: Hashable, Sendable, Codable {
    public internal(set) var banked: Int
    /// The last day whose baseline was granted.
    public internal(set) var baselineDay: LocalDay?
    /// Resisted reaches that earned a round today, for their cap.
    public internal(set) var earned: DayCount?
    /// Rounds played today, for the daily cap.
    public internal(set) var played: DayCount?

    public init() {
        banked = 0
        baselineDay = nil
        earned = nil
        played = nil
    }

    /// Rounds that can be played on `day`: banked (with the day's baseline,
    /// if not yet granted), within the day's remaining plays.
    public func playable(on day: LocalDay, rules: RoundRules) -> Int {
        let bank = banked + (baselineDay == day ? 0 : rules.dailyBaseline)
        return max(0, min(bank, rules.playsPerDay - plays(on: day)))
    }

    /// Rounds played on `day`.
    public func plays(on day: LocalDay) -> Int {
        played.flatMap { $0.day == day ? $0.count : nil } ?? 0
    }

    /// Grants `day`'s baseline once.
    mutating func grantBaseline(on day: LocalDay, rules: RoundRules) {
        guard baselineDay != day else { return }
        if let last = baselineDay, last > day { return }
        banked += rules.dailyBaseline
        baselineDay = day
    }

    /// A resisted reach on `day`: one more round, up to the day's cap.
    ///
    /// - Returns: Whether it earned a round.
    @discardableResult
    public mutating func earnForResist(on day: LocalDay, rules: RoundRules) -> Bool {
        grantBaseline(on: day, rules: rules)
        let used = earned.flatMap { $0.day == day ? $0.count : nil } ?? 0
        guard rules.perResistedReach > 0, used < rules.resistedReachesPerDay else { return false }
        earned = DayCount(day: day, count: used + 1)
        banked += rules.perResistedReach
        return true
    }

    /// Spends one banked round on `day`.
    public mutating func play(on day: LocalDay, rules: RoundRules) throws {
        grantBaseline(on: day, rules: rules)
        guard plays(on: day) < rules.playsPerDay else { throw RoundError.dailyLimitReached }
        guard banked > 0 else { throw RoundError.noRoundBanked }
        banked -= 1
        played = DayCount(day: day, count: plays(on: day) + 1)
    }
}
