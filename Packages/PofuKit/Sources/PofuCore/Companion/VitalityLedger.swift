import Foundation

/// One settled day of the companion's vitality.
public struct VitalityDay: Hashable, Sendable, Codable {
    public let day: LocalDay
    /// Vitality at the end of the day.
    public let vitality: Double
    /// Whether Pofu could observe the day. Unobserved days carry vitality
    /// forward unchanged.
    public let isObserving: Bool

    public init(day: LocalDay, vitality: Double, isObserving: Bool) {
        self.day = day
        self.vitality = vitality
        self.isObserving = isObserving
    }
}

/// The companion's vitality over time: the value settled at the end of the
/// last complete day, and a short history.
///
/// Days settle once, in order, the first time the app runs after they end.
/// Today is never settled; its live value is derived from the running
/// input (`live(today:model:)`), so Pofu reacts during the day without a
/// single evening deciding the week.
public struct VitalityLedger: Hashable, Sendable, Codable {
    /// Vitality at the end of `settledThrough`.
    public private(set) var settled: Double
    /// The newest settled day; `nil` before the first settlement.
    public private(set) var settledThrough: LocalDay?
    /// Settled days, oldest first, at most `historyLimit` of them.
    public private(set) var history: [VitalityDay]

    public static let historyLimit = 35
    /// The most days one settlement walks through. Longer absences are
    /// unobserved anyway, so skipping ahead changes nothing.
    public static let maximumCatchUpDays = 400

    public init(initialVitality: Double = VitalityRules().initialVitality) {
        self.settled = Rounding.unitInterval(initialVitality)
        self.settledThrough = nil
        self.history = []
    }

    /// Settles every day after `settledThrough`, up to and including `day`.
    ///
    /// Call with yesterday. On the very first call nothing is settled: the
    /// ledger starts at `day` with its initial vitality, because Pofu did
    /// not exist before. A `day` at or before `settledThrough` (including a
    /// clock that moved backwards) changes nothing.
    ///
    /// - Parameter input: The finished input of a day.
    public mutating func settle(
        through day: LocalDay,
        model: VitalityModel,
        input: (LocalDay) -> VitalityInput
    ) {
        guard let last = settledThrough else {
            settledThrough = day
            return
        }
        guard day > last else { return }

        var next = last.adding(days: 1)
        let earliest = day.adding(days: -Self.maximumCatchUpDays)
        if next < earliest {
            next = earliest
        }
        while next <= day {
            let dayInput = input(next)
            settled = model.vitality(after: dayInput, from: settled)
            history.append(VitalityDay(day: next, vitality: settled, isObserving: dayInput.isObserving))
            next = next.adding(days: 1)
        }
        if history.count > Self.historyLimit {
            history.removeFirst(history.count - Self.historyLimit)
        }
        settledThrough = day
    }

    /// Today's live vitality: the settled value moved by today's running
    /// input. An unobserved day so far shows the settled value.
    public func live(today input: VitalityInput, model: VitalityModel) -> Double {
        model.vitality(after: input, from: settled)
    }
}

extension VitalityInput {
    /// The input of local day `day` as far as Pofu observed it.
    ///
    /// - Impulses are the day's resolved check-ins.
    /// - Distracting minutes are approximated by the length of the passes
    ///   granted that day, until the Screen Time report extension measures
    ///   real usage.
    /// - The day counts as observed when the automation reported anything:
    ///   a check-in or a pass-through. A day without a single reach cannot
    ///   be told apart from a deleted automation before DeviceActivity is
    ///   available, so it freezes vitality instead of rewarding blindness.
    public static func observed(
        on day: LocalDay,
        in state: PofuState,
        calendar: Calendar
    ) -> VitalityInput {
        let records = state.checkIns.filter { LocalDay(containing: $0.attemptedAt, in: calendar) == day }
        let passThroughs = state.passThroughs.filter { LocalDay(containing: $0.at, in: calendar) == day }
        let minutes = records.compactMap(\.outcome.pass).reduce(0.0) { total, pass in
            total + pass.expiresAt.timeIntervalSince(pass.grantedAt) / 60
        }
        return VitalityInput(
            distractingMinutes: minutes,
            impulses: ImpulseMetrics.daily(on: day, from: records, calendar: calendar),
            activityEnergy: state.wallet.activityEnergy(on: day),
            isObserving: !records.isEmpty || !passThroughs.isEmpty
        )
    }
}
