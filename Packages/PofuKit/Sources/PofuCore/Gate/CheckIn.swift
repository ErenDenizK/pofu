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
    /// Use today's free emergency pass. Only on `pay` and `askFriend`, and
    /// once per local day.
    case emergency
}

/// Why the user says they are opening an app, asked on the `intent` rung.
/// Logged with the check-in and reflected back in the recap.
public enum IntentReason: String, Hashable, Sendable, Codable, CaseIterable {
    case reply
    case lookUp
    case post
    case bored
    case habit
    case needBreak
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

/// Where a reach was met: in Hop! (the soft gate) or on the Screen Time
/// shield. Both feed the north-star metric; copy and the recap tell them
/// apart (ADR-0013).
public enum CheckInChannel: String, Hashable, Sendable, Codable {
    case softGate
    case shield
}

/// How a reach met on the Screen Time shield ended without Hop!. Each kind
/// is logged on its own, so the readout can show the strict number (taps
/// only) next to the full one (gate v2, section 12).
public enum ShieldResolution: String, Hashable, Sendable, Codable, CaseIterable {
    /// "Skip it" on the shield.
    case skipped
    /// The shield was left without any tap.
    case silentLeave
    /// "Open with Pofu", then nothing for the request's lifetime.
    case abandonedRequest
    /// "Skip it" on the shield waiting for the notification tap.
    case requestCancelled
    /// "Just 3 minutes" on the shield: the app was opened.
    case quickCheck
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
    /// The reason the user gave on the `intent` rung, if any.
    public let reason: IntentReason?
    /// Where the reach was met; `nil` in records from before the shield,
    /// which were all Hop!.
    public let channel: CheckInChannel?
    /// How a reach at the shield ended, when it ended there; `nil` for
    /// Hop! and for records from before gate v2.
    public let shieldResolution: ShieldResolution?

    public init(
        id: UUID,
        target: TargetGroupID,
        attemptedAt: Date,
        resolvedAt: Date,
        rung: FrictionRung,
        outcome: CheckInOutcome,
        reason: IntentReason? = nil,
        channel: CheckInChannel? = nil,
        shieldResolution: ShieldResolution? = nil
    ) {
        self.id = id
        self.target = target
        self.attemptedAt = attemptedAt
        self.resolvedAt = resolvedAt
        self.rung = rung
        self.outcome = outcome
        self.reason = reason
        self.channel = channel
        self.shieldResolution = shieldResolution
    }

    /// Where the reach was met, reading old records as Hop!.
    public var resolvedChannel: CheckInChannel {
        channel ?? .softGate
    }
}

/// An open that a valid pass covered: Pofu let it through silently. Not an
/// attempt, but proof that the automation for `target` is alive.
public struct PassThrough: Hashable, Sendable, Codable {
    public let target: TargetGroupID
    public let at: Date
    public let passID: UUID

    public init(target: TargetGroupID, at: Date, passID: UUID) {
        self.target = target
        self.at = at
        self.passID = passID
    }
}

/// Why resolving a check-in failed.
public enum CheckInError: Error, Hashable, Sendable {
    /// The choice is not available on the attempt's rung.
    case choiceNotAvailable(CheckInChoice, rung: FrictionRung)
    /// Paying failed.
    case spend(SpendError)
    /// Today's emergency pass is already used; the next one is available
    /// on `nextAvailable`.
    case emergencyPassUsed(nextAvailable: LocalDay)
}
