import Foundation

/// The rungs of the friction ladder (vision.md), from gentlest to firmest.
///
/// Seeds never buy screen time (ADR-0015), so both rungs are free: there is
/// no paying rung and no asking a friend to pay for the user. Records saved
/// before ADR-0015 may hold the removed `pay` (2) and `askFriend` (3)
/// rungs; they decode as `intent`.
public enum FrictionRung: Int, Hashable, Sendable, Codable, CaseIterable, Comparable {
    /// A short breathing moment, then the user may continue for free.
    case pause = 0
    /// "What are you opening this for?", then the user may continue for
    /// free.
    case intent = 1

    public static func < (lhs: FrictionRung, rhs: FrictionRung) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self = FrictionRung(rawValue: raw) ?? .intent
    }

    /// The next rung up; `intent` is the top.
    public var next: FrictionRung {
        FrictionRung(rawValue: rawValue + 1) ?? .intent
    }
}

/// Tracks how far up the friction ladder repeated attempts have climbed.
///
/// Every open attempt less than `cooldown` after the previous attempt climbs
/// one rung, up to `highestAttemptRung`. An attempt after a longer gap
/// starts again at `pause`. If the clock moves backwards, the attempt
/// counts as inside the cooldown, which errs on the side of more friction.
public struct FrictionLadder: Hashable, Sendable, Codable {
    public private(set) var lastAttemptAt: Date?
    public private(set) var lastRung: FrictionRung?

    public init() {
        self.lastAttemptAt = nil
        self.lastRung = nil
    }

    /// The rung an attempt at `date` would land on, without recording it.
    public func rung(forAttemptAt date: Date, rules: FrictionRules) -> FrictionRung {
        guard
            let lastAttemptAt,
            let lastRung,
            date.timeIntervalSince(lastAttemptAt) < rules.cooldown
        else {
            return .pause
        }
        return min(lastRung.next, rules.highestAttemptRung)
    }

    /// Records an attempt at `date` and returns the rung it lands on.
    @discardableResult
    public mutating func registerAttempt(at date: Date, rules: FrictionRules) -> FrictionRung {
        let landed = self.rung(forAttemptAt: date, rules: rules)
        lastAttemptAt = date
        lastRung = landed
        return landed
    }
}
