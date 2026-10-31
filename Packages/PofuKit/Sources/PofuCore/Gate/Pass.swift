import Foundation

/// Identifies a group of distracting apps the user protects together, such
/// as "Instagram" or "Short video". The app layer maps it to the opaque
/// Screen Time tokens of that group.
public struct TargetGroupID: RawRepresentable, Hashable, Sendable, Codable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }
}

/// Why a pass exists.
public enum PassSource: Hashable, Sendable, Codable {
    /// Granted after a free rung of the friction ladder.
    case free(FrictionRung)
    /// Bought with energy.
    case purchased(price: Energy)
    /// Approved by a friend (ADR-0005).
    case friendApproved
}

/// Time-boxed permission to use a target group (ADR-0008).
///
/// While a pass is valid, the soft gate lets the app open without
/// intervening, and the open does not count as a new attempt.
public struct Pass: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let target: TargetGroupID
    public let grantedAt: Date
    public let expiresAt: Date
    public let source: PassSource

    public init(
        id: UUID = UUID(),
        target: TargetGroupID,
        grantedAt: Date,
        expiresAt: Date,
        source: PassSource
    ) {
        self.id = id
        self.target = target
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.source = source
    }

    /// Creates a pass that lasts `minutes` from `grantedAt`.
    public init(
        id: UUID = UUID(),
        target: TargetGroupID,
        grantedAt: Date,
        minutes: Int,
        source: PassSource
    ) {
        self.init(
            id: id,
            target: target,
            grantedAt: grantedAt,
            expiresAt: grantedAt.addingTimeInterval(TimeInterval(max(0, minutes)) * 60),
            source: source
        )
    }

    /// Valid from `grantedAt` (inclusive) until `expiresAt` (exclusive).
    public func isValid(at date: Date) -> Bool {
        grantedAt <= date && date < expiresAt
    }

    /// Seconds of validity left at `date`; zero when not valid.
    public func remaining(at date: Date) -> TimeInterval {
        isValid(at: date) ? expiresAt.timeIntervalSince(date) : 0
    }
}

/// The passes a user holds, answering "is there a valid pass for this
/// target at this time?"
public struct PassLedger: Hashable, Sendable, Codable {
    public private(set) var passes: [Pass]

    public init(passes: [Pass] = []) {
        self.passes = passes
    }

    public mutating func grant(_ pass: Pass) {
        passes.append(pass)
    }

    /// The valid pass for `target` at `date` that lasts longest, if any.
    public func validPass(for target: TargetGroupID, at date: Date) -> Pass? {
        passes
            .filter { $0.target == target && $0.isValid(at: date) }
            .max { $0.expiresAt < $1.expiresAt }
    }

    public func hasValidPass(for target: TargetGroupID, at date: Date) -> Bool {
        validPass(for: target, at: date) != nil
    }

    /// Drops passes that have expired by `date`. Passes that start in the
    /// future are kept.
    public mutating func removeExpired(at date: Date) {
        passes.removeAll { $0.expiresAt <= date }
    }

    /// Ends every pass for `target` immediately, for example when the user
    /// leaves the app early and wants their protection back.
    public mutating func revokeAll(for target: TargetGroupID) {
        passes.removeAll { $0.target == target }
    }
}
