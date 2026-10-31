import Foundation

/// What one day contributes to the companion's vitality.
public struct VitalityInput: Hashable, Sendable, Codable {
    /// Minutes spent in distracting apps.
    public var distractingMinutes: Double
    /// The day's impulse counts.
    public var impulses: ImpulseMetrics
    /// Energy earned through activities (honor, verified, and steps).
    public var activityEnergy: Energy

    public init(
        distractingMinutes: Double = 0,
        impulses: ImpulseMetrics = ImpulseMetrics(),
        activityEnergy: Energy = .zero
    ) {
        self.distractingMinutes = distractingMinutes
        self.impulses = impulses
        self.activityEnergy = activityEnergy
    }
}

/// The companion's mood band, which selects Pofu's base pose
/// (docs/brand/character.md).
public enum VitalityBand: String, Hashable, Sendable, Codable, CaseIterable {
    case wilting
    case tired
    case content
    case thriving
}

/// Derives the companion's vitality, a wellbeing value in `0...1`.
///
/// Each day gets a score from three components, each in `0...1`:
///
/// - usage `U = clamp(1 − (minutes / budget) / zeroMultiple)`: 1 with no
///   distracting use, 0.5 at the budget, 0 at twice the budget (defaults).
/// - resistance `R = resisted / attempts`, or 1 when there were no attempts:
///   no reflex at all is the best case.
/// - activity `A = energy / (energy + halfSaturation)`: diminishing returns,
///   0.5 at 30 energy (one hour of honor activity).
///
/// The day score is the weighted mean `S = (wU·U + wR·R + wA·A) / (wU + wR + wA)`
/// and vitality is its exponential moving average across days,
/// `V(d) = V(d−1) + α · (S(d) − V(d−1))`. With α = 0.3 no single day moves
/// vitality by more than 0.3, so Pofu reflects habits, not one bad evening.
/// Because every term lies in `0...1`, vitality always does too.
public struct VitalityModel: Sendable {
    public let rules: VitalityRules

    public init(rules: VitalityRules = VitalityRules()) {
        self.rules = rules
    }

    public func usageScore(distractingMinutes: Double) -> Double {
        let minutes = distractingMinutes.isNaN ? 0 : max(0, distractingMinutes)
        guard rules.dailyBudgetMinutes > 0, rules.usageZeroAtBudgetMultiple > 0 else {
            return minutes > 0 ? 0 : 1
        }
        let usageRatio = minutes / rules.dailyBudgetMinutes
        return Rounding.unitInterval(1 - usageRatio / rules.usageZeroAtBudgetMultiple)
    }

    public func resistanceScore(_ impulses: ImpulseMetrics) -> Double {
        Rounding.unitInterval(impulses.resistedRatio ?? 1)
    }

    public func activityScore(energy: Energy) -> Double {
        let earned = Double(max(energy.units, 0))
        let half = Double(max(rules.activityHalfSaturation.units, 0))
        guard earned + half > 0 else { return 0 }
        return Rounding.unitInterval(earned / (earned + half))
    }

    /// The day score `S`, in `0...1`.
    public func dailyScore(_ input: VitalityInput) -> Double {
        let usageWeight = max(0, rules.usageWeight.isNaN ? 0 : rules.usageWeight)
        let resistedWeight = max(0, rules.resistedWeight.isNaN ? 0 : rules.resistedWeight)
        let activityWeight = max(0, rules.activityWeight.isNaN ? 0 : rules.activityWeight)
        let usage = usageScore(distractingMinutes: input.distractingMinutes)
        let totalWeight = usageWeight + resistedWeight + activityWeight
        guard totalWeight > 0, totalWeight.isFinite else {
            return usage
        }
        let weighted =
            usageWeight * usage
            + resistedWeight * resistanceScore(input.impulses)
            + activityWeight * activityScore(energy: input.activityEnergy)
        return Rounding.unitInterval(weighted / totalWeight)
    }

    /// Vitality after a day with `input`, starting from `previous`.
    ///
    /// For a live view during the day, pass the running input of today and
    /// yesterday's settled vitality as `previous`.
    public func vitality(after input: VitalityInput, from previous: Double) -> Double {
        let alpha = Rounding.unitInterval(rules.smoothing)
        let start = Rounding.unitInterval(previous)
        return Rounding.unitInterval(start + alpha * (dailyScore(input) - start))
    }

    /// Vitality after each of `days`, in order, starting from
    /// `initialVitality`.
    public func trajectory(of days: [VitalityInput]) -> [Double] {
        var current = rules.initialVitality
        return days.map { input in
            current = vitality(after: input, from: current)
            return current
        }
    }

    /// The mood band for a vitality value.
    public func band(for vitality: Double) -> VitalityBand {
        let value = Rounding.unitInterval(vitality)
        if value >= rules.thrivingThreshold { return .thriving }
        if value >= rules.contentThreshold { return .content }
        if value >= rules.tiredThreshold { return .tired }
        return .wilting
    }
}
