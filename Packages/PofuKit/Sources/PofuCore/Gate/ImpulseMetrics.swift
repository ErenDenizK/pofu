import Foundation

/// One day's impulse counts: the north-star metric, impulses resisted.
public struct ImpulseMetrics: Hashable, Sendable, Codable {
    /// Interventions that ended, whatever the outcome.
    public var attempts: Int
    /// Attempts that ended without opening the app.
    public var resisted: Int
    /// Attempts where the user continued, for free or by paying.
    public var proceeded: Int
    /// Attempts where a friend approved continuing.
    public var friendApproved: Int

    public init(attempts: Int = 0, resisted: Int = 0, proceeded: Int = 0, friendApproved: Int = 0) {
        self.attempts = attempts
        self.resisted = resisted
        self.proceeded = proceeded
        self.friendApproved = friendApproved
    }

    /// Attempts that ended with the app open.
    public var opened: Int {
        proceeded + friendApproved
    }

    /// Share of attempts resisted, in `0...1`; `nil` when there were no
    /// attempts, because "no impulses" is not the same as "0% resisted".
    public var resistedRatio: Double? {
        attempts == 0 ? nil : Double(resisted) / Double(attempts)
    }

    /// Adds one completed check-in.
    public mutating func record(_ outcome: CheckInOutcome) {
        attempts += 1
        switch outcome {
        case .resisted:
            resisted += 1
        case .proceeded:
            proceeded += 1
        case .friendApproved:
            friendApproved += 1
        }
    }

    /// The metrics of the local day `day`, attributing each check-in to the
    /// day its attempt started on.
    public static func daily(
        on day: LocalDay,
        from records: [CheckInRecord],
        calendar: Calendar
    ) -> ImpulseMetrics {
        var metrics = ImpulseMetrics()
        for record in records where LocalDay(containing: record.attemptedAt, in: calendar) == day {
            metrics.record(record.outcome)
        }
        return metrics
    }
}
