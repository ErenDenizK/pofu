import Foundation

/// An open attempt that the soft gate intercepted (ADR-0008).
public struct CheckInAttempt: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let target: TargetGroupID
    public let attemptedAt: Date
    /// The rung that the pattern of attempts reached.
    public let ladderRung: FrictionRung
    /// The rung the user faces: `ladderRung`, raised to `askFriend` when
    /// paying is due but unaffordable.
    public let rung: FrictionRung
    /// The cheapest unlock on offer at the time of the attempt.
    public let cheapestPrice: Energy?

    public init(
        id: UUID,
        target: TargetGroupID,
        attemptedAt: Date,
        ladderRung: FrictionRung,
        rung: FrictionRung,
        cheapestPrice: Energy?
    ) {
        self.id = id
        self.target = target
        self.attemptedAt = attemptedAt
        self.ladderRung = ladderRung
        self.rung = rung
        self.cheapestPrice = cheapestPrice
    }
}

/// What the gate decided when an app was opened.
public enum CheckInDecision: Hashable, Sendable {
    /// A valid pass covers the open: let it through silently. This is not
    /// an attempt and does not climb the ladder.
    case covered(Pass)
    /// Pofu intervenes on the given rung.
    case intervene(CheckInAttempt)
}

/// What the user chose during an intervention.
public enum CheckInChoice: Hashable, Sendable {
    /// Leave without opening the app.
    case resist
    /// Continue for free with a short pass. Only on `pause` and `intent`.
    case proceed
    /// Buy an unlock window. Allowed on any rung; fails when unaffordable.
    case pay(minutes: Int)
    /// A friend approved an unlock window. Only on `askFriend`.
    case friendApproved(minutes: Int)
}

/// How an attempt ended. The north-star metric counts `resisted`.
public enum CheckInOutcome: Hashable, Sendable, Codable {
    case resisted
    case proceeded(Pass)
    case friendApproved(Pass)

    /// The pass the outcome granted, if any.
    public var pass: Pass? {
        switch self {
        case .resisted:
            nil
        case .proceeded(let pass), .friendApproved(let pass):
            pass
        }
    }

    public var isResisted: Bool {
        self == .resisted
    }
}

/// A completed check-in: the attempt and how it ended.
public struct CheckInRecord: Hashable, Sendable, Codable, Identifiable {
    /// The id of the attempt.
    public let id: UUID
    public let target: TargetGroupID
    public let attemptedAt: Date
    public let resolvedAt: Date
    public let rung: FrictionRung
    public let outcome: CheckInOutcome

    public init(
        id: UUID,
        target: TargetGroupID,
        attemptedAt: Date,
        resolvedAt: Date,
        rung: FrictionRung,
        outcome: CheckInOutcome
    ) {
        self.id = id
        self.target = target
        self.attemptedAt = attemptedAt
        self.resolvedAt = resolvedAt
        self.rung = rung
        self.outcome = outcome
    }
}

/// Why resolving a check-in failed.
public enum CheckInError: Error, Hashable, Sendable {
    /// The choice is not available on the attempt's rung.
    case choiceNotAvailable(CheckInChoice, rung: FrictionRung)
    /// Paying failed.
    case spend(SpendError)
}
