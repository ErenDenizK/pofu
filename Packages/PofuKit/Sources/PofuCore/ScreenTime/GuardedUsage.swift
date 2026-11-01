import Foundation

/// The DeviceActivity usage thresholds that measure guarded minutes, and
/// how they map to the daily breath limit (ADR-0015).
///
/// DeviceActivity cannot report minutes directly; it can only call back
/// when cumulative use of the selection crosses a threshold. Pofu schedules
/// one event per step, so it knows today's guarded time to the step: "at
/// least 30 minutes" after the 30-minute event. The last step is the breath
/// limit, so crossing it is measured, never estimated from passes.
public struct GuardedUsageLadder: Hashable, Sendable {
    /// The thresholds, in guarded minutes a day, ascending.
    public let stepsMinutes: [Int]
    /// Guarded minutes a day after which every open first waits for a
    /// breathing break (ADR-0015).
    public let breathLimitMinutes: Int

    /// 15, 30, 45, and 60 minutes; the breath limit is 60.
    public static let standard = GuardedUsageLadder(stepsMinutes: [15, 30, 45, 60], breathLimitMinutes: 60)

    /// The prefix of every threshold's event and activity name.
    public static let namePrefix = "pofu.usage."

    /// - Precondition: steps are positive and the breath limit is one of
    ///   them, so crossing it is always measured.
    public init(stepsMinutes: [Int], breathLimitMinutes: Int) {
        let steps = Array(Set(stepsMinutes.filter { $0 > 0 })).sorted()
        precondition(steps.contains(breathLimitMinutes), "The breath limit must be a measured step")
        self.stepsMinutes = steps
        self.breathLimitMinutes = breathLimitMinutes
    }

    /// The name of the event (and its activity) that fires at `minutes`.
    public func thresholdName(forMinutes minutes: Int) -> String {
        Self.namePrefix + String(minutes)
    }

    /// Every threshold, as names and seconds of use, ascending.
    public var thresholds: [(name: String, seconds: TimeInterval)] {
        stepsMinutes.map { (thresholdName(forMinutes: $0), TimeInterval($0) * 60) }
    }

    /// The step a threshold name stands for; `nil` for names that are not
    /// one of this ladder's steps.
    public func minutes(forThresholdName name: String) -> Int? {
        guard name.hasPrefix(Self.namePrefix), let minutes = Int(name.dropFirst(Self.namePrefix.count)) else {
            return nil
        }
        return stepsMinutes.contains(minutes) ? minutes : nil
    }

    /// Whether `measuredMinutes` of guarded time today reaches the breath
    /// limit.
    public func isBreathLimitReached(measuredMinutes: Int) -> Bool {
        measuredMinutes >= breathLimitMinutes
    }

    /// The next step still ahead of `measuredMinutes`, or `nil` past the
    /// last one.
    public func nextStep(after measuredMinutes: Int) -> Int? {
        stepsMinutes.first { $0 > measuredMinutes }
    }
}

/// Today's measured guarded time: the highest threshold crossed on `day`.
public struct GuardedUsageDay: Hashable, Sendable, Codable {
    public var day: LocalDay
    /// At least this many guarded minutes were used on `day`.
    public var measuredMinutes: Int

    public init(day: LocalDay, measuredMinutes: Int) {
        self.day = day
        self.measuredMinutes = measuredMinutes
    }
}
