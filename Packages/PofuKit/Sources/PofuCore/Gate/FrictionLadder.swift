import Foundation

/// The rungs of the friction ladder (vision.md), from gentlest to firmest.
public enum FrictionRung: Int, Hashable, Sendable, Codable, CaseIterable, Comparable {
    /// A short breathing moment, then the user may continue for free.
    case pause = 0
    /// "What are you opening this for?", then the user may continue for
    /// free.
    case intent = 1
    /// Continuing costs energy.
    case pay = 2
    /// Only a friend can approve continuing.
    case askFriend = 3

    public static func < (lhs: FrictionRung, rhs: FrictionRung) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The next rung up; `askFriend` is the top.
    public var next: FrictionRung {
        FrictionRung(rawValue: rawValue + 1) ?? .askFriend
    }

    /// Whether the user may continue on this rung without paying.
    public var isFree: Bool {
        self == .pause || self == .intent
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

    /// The rung the user actually faces: once continuing would cost energy
    /// and the balance cannot cover any unlock, only a friend can help.
    public static func effectiveRung(
        ladderRung: FrictionRung,
        canAffordAnyUnlock: Bool
    ) -> FrictionRung {
        if ladderRung >= .pay && !canAffordAnyUnlock {
            return .askFriend
        }
        return ladderRung
    }
}
