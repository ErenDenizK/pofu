import Foundation

/// How Pofu feels, as the meter's mood word (game design §5). The meter
/// shows a soft bar and this word, never a number.
public enum WellbeingBand: String, Hashable, Sendable, Codable, CaseIterable, Comparable {
    case curledUp
    case unwell
    case tired
    case content
    case cozy

    public static func < (lhs: WellbeingBand, rhs: WellbeingBand) -> Bool {
        allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
    }
}

/// Pofu's wellbeing (*keyif*): a continuous meter from the floor (5) to
/// 100 that guarded-app time drains and calm heals (game design §5,
/// ADR-0015, ADR-0017).
///
/// Pofu never dies: every operation clamps to `CareRules.floor`, the
/// "curled up" state, from which a quiet hour visibly lifts him and every
/// night he sleeps part of a bad day off. The ledger is plain data with
/// pure, deterministic operations; `WorldClock` decides when each applies.
public struct CareLedger: Hashable, Sendable, Codable {
    /// Wellbeing, within `CareRules.floor...CareRules.ceiling`.
    public internal(set) var wellbeing: Double
    /// Resisted reaches that healed Pofu today, for the daily cap.
    public internal(set) var healedSkips: DayCount?

    public init(rules: CareRules = CareRules()) {
        self.init(wellbeing: rules.start, rules: rules)
    }

    public init(wellbeing: Double, rules: CareRules = CareRules()) {
        self.wellbeing = Self.clamped(wellbeing, rules)
        self.healedSkips = nil
    }

    /// Pofu's mood word.
    public func band(rules: CareRules) -> WellbeingBand {
        switch wellbeing {
        case rules.cozyFrom...: .cozy
        case rules.contentFrom...: .content
        case rules.tiredFrom...: .tired
        case rules.unwellFrom...: .unwell
        default: .curledUp
        }
    }

    /// Station production, in tenths of its rate: below "tired" the
    /// residents stop to look after Pofu.
    public func productionTenths(rules: CareRules) -> Int {
        wellbeing < rules.tiredFrom ? min(max(rules.unwellProductionTenths, 0), 10) : 10
    }

    // MARK: - Changes

    /// One minute in a guarded app: the drain, ×2 inside bedtime, ×1.25
    /// for each earlier open in the escalation window.
    public mutating func drainMinute(earlierOpens: Int, atNight: Bool, rules: CareRules) {
        let night = atNight ? rules.nightDrainMultiplier : 1
        let escalation = pow(rules.escalationPerEarlierOpen, Double(max(0, earlierOpens)))
        change(by: -rules.drainPerMinute * night * escalation, rules: rules)
    }

    /// One minute of calm waking time.
    ///
    /// From "tired" up, a flat `healPerCalmHour` / 60. In the two lowest
    /// bands ("curled up" and "unwell"), 1/60 of the band's width, stopping
    /// at its upper edge: one quiet hour lifts Pofu out of either band from
    /// anywhere in it (ADR-0017's "one quiet hour lifts him a band", from
    /// the floor), and never past the next edge in that minute.
    public mutating func healMinute(rules: CareRules) {
        guard wellbeing < rules.tiredFrom else {
            change(by: rules.healPerCalmHour / 60, rules: rules)
            return
        }
        let bounds = bandBounds(rules: rules)
        // A hair over 1/60, so sixty minutes from the floor always reach
        // the edge despite rounding; the edge caps the overshoot.
        let step = (bounds.upper - bounds.lower) / 60 * (1 + 1e-9)
        guard step > 0 else { return }
        let next = min(wellbeing + step, bounds.upper)
        wellbeing = Self.clamped(next, rules)
    }

    /// The band Pofu is in, as `lower..<upper` (the top band ends at the
    /// ceiling).
    public func bandBounds(rules: CareRules) -> (lower: Double, upper: Double) {
        let floor = rules.floor.isFinite ? rules.floor : 5
        let ceiling = max(floor, rules.ceiling.isFinite ? rules.ceiling : 100)
        let edges = [floor, rules.unwellFrom, rules.tiredFrom, rules.contentFrom, rules.cozyFrom, ceiling]
        for index in 0..<(edges.count - 1) where wellbeing < edges[index + 1] {
            return (edges[index], edges[index + 1])
        }
        return (rules.cozyFrom, ceiling)
    }

    /// A guarded app opened: the reach itself.
    public mutating func opened(rules: CareRules) {
        change(by: -rules.drainPerOpen, rules: rules)
    }

    /// A resisted reach on `day`: +1, for at most `healedSkipsPerDay`.
    ///
    /// - Returns: Whether it healed.
    @discardableResult
    public mutating func skipped(on day: LocalDay, rules: CareRules) -> Bool {
        let used = healedSkips.flatMap { $0.day == day ? $0.count : nil } ?? 0
        guard used < rules.healedSkipsPerDay else { return false }
        healedSkips = DayCount(day: day, count: used + 1)
        change(by: rules.healPerSkip, rules: rules)
        return true
    }

    /// The bedtime window ended. Pofu sleeps it off (below the recovery
    /// target, part of the way back to it), and a calm night heals him.
    public mutating func nightEnded(calm: Bool, rules: CareRules) {
        if wellbeing < rules.recoveryTarget {
            change(by: Rounding.unitInterval(rules.nightRecoveryShare) * (rules.recoveryTarget - wellbeing), rules: rules)
        }
        if calm {
            change(by: rules.calmNightHeal, rules: rules)
        }
    }

    // MARK: - Private

    private mutating func change(by amount: Double, rules: CareRules) {
        guard amount.isFinite else { return }
        wellbeing = Self.clamped(wellbeing + amount, rules)
    }

    private static func clamped(_ value: Double, _ rules: CareRules) -> Double {
        let floor = rules.floor.isFinite ? rules.floor : 5
        let ceiling = max(floor, rules.ceiling.isFinite ? rules.ceiling : 100)
        guard !value.isNaN else { return floor }
        return min(max(value, floor), ceiling)
    }
}
