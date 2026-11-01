import Foundation

/// What the user did in real life.
public enum ActivityKind: String, Hashable, Sendable, Codable, CaseIterable {
    case focus
    case study
    case exercise
    case walk
    case chores
    case creative
    case custom
}

/// How an activity was confirmed (ADR-0004: trust first, verification as a
/// bonus).
public enum VerificationLevel: String, Hashable, Sendable, Codable, CaseIterable {
    /// Self-reported with a timer. Earns the base rate, subject to a daily
    /// soft cap.
    case honor
    /// Observed without user effort, for example HealthKit workouts.
    case passive
    /// Proves itself, for example a focus session completed while shielded.
    case structural
    /// Confirmed on purpose, for example camera-counted repetitions.
    case active

    /// Whether this level earns the verified multiplier.
    public var isVerified: Bool {
        self != .honor
    }
}

/// One completed, timed activity.
public struct ActivitySession: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var kind: ActivityKind
    public var verification: VerificationLevel
    public var startedAt: Date
    public var endedAt: Date
    /// The user's own label for `.custom` activities.
    public var customTitle: String?

    public init(
        id: UUID = UUID(),
        kind: ActivityKind,
        verification: VerificationLevel,
        startedAt: Date,
        endedAt: Date,
        customTitle: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.verification = verification
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.customTitle = customTitle
    }

    /// Whole minutes between start and end. Partial minutes do not count;
    /// a session that ends before it starts counts as zero.
    public var wholeMinutes: Int {
        max(0, Rounding.down(endedAt.timeIntervalSince(startedAt) / 60))
    }
}

/// The result of crediting an activity.
public struct EarningResult: Hashable, Sendable {
    /// Energy added to the balance.
    public let earned: Energy
    /// Energy the activity would have earned but did not, because the honor
    /// daily cap was reached. Shown to the user so the cap is never a
    /// silent surprise.
    public let forfeitedToCap: Energy
    /// The activity ended on a day older than the retained history, so it
    /// was not credited at all.
    public let wasStale: Bool

    public init(earned: Energy, forfeitedToCap: Energy = .zero, wasStale: Bool = false) {
        self.earned = earned
        self.forfeitedToCap = forfeitedToCap
        self.wasStale = wasStale
    }

    /// What the activity was worth before the cap.
    public var gross: Energy {
        earned + forfeitedToCap
    }
}

/// An honor-system session in progress: the user started a timer and Pofu
/// trusts them (ADR-0004). Persisted, so a session survives the app being
/// closed and is credited from its start time.
public struct ActiveSession: Hashable, Sendable, Codable {
    public var kind: ActivityKind
    public var startedAt: Date
    public var plannedMinutes: Int

    public init(kind: ActivityKind, startedAt: Date, plannedMinutes: Int) {
        self.kind = kind
        self.startedAt = startedAt
        self.plannedMinutes = max(0, plannedMinutes)
    }

    /// When the timer runs out.
    public var plannedEnd: Date {
        startedAt.addingTimeInterval(TimeInterval(plannedMinutes) * 60)
    }

    /// Seconds left at `date`, never negative.
    public func remaining(at date: Date) -> TimeInterval {
        max(0, plannedEnd.timeIntervalSince(date))
    }

    /// Whether the timer has run out at `date`.
    public func isComplete(at date: Date) -> Bool {
        date >= plannedEnd
    }

    /// The session as credited when it ends at `date`: never past the
    /// planned end, so an app opened hours later does not earn more.
    public func completed(at date: Date) -> ActivitySession {
        ActivitySession(
            kind: kind,
            verification: .honor,
            startedAt: startedAt,
            endedAt: min(max(date, startedAt), plannedEnd)
        )
    }
}
