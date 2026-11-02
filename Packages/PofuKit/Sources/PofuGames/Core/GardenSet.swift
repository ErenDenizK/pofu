/// A set: five rounds, then a natural stop (archipelago-system §4.2).
///
/// A set never starts by itself and never chains: after its fifth round
/// the primary action is "Enough for today", and another set is a plain
/// text button that only shows when earned rounds are banked. Rounds are
/// earned by resisting reaches; `roundsAvailable` comes from the ledger
/// (`RoundLedger`, not yet in PofuCore; the debug entry passes a number).
public struct GardenSet: Sendable, Equatable {
    public static let roundsPerSet = 5

    public let seed: UInt64
    /// Earned rounds banked when the set started, capped by the daily
    /// limit (at most 12 a day).
    public let roundsAvailable: Int
    public private(set) var results: [GardenRoundResult] = []

    public init(seed: UInt64, roundsAvailable: Int) {
        self.seed = seed
        self.roundsAvailable = max(0, roundsAvailable)
    }

    /// Rounds this set will hold: five, or fewer when fewer are earned.
    public var length: Int { min(Self.roundsPerSet, roundsAvailable) }
    /// The round being played, from 1.
    public var roundNumber: Int { min(results.count + 1, max(1, length)) }
    public var isComplete: Bool { results.count >= length }
    public var seedsTotal: Int { results.reduce(0) { $0 + $1.seeds } }
    /// Earned rounds still banked after this set.
    public var roundsLeftAfterSet: Int { max(0, roundsAvailable - results.count) }

    /// The seed of round `number` (from 1); independent of how the other
    /// rounds were played.
    public func roundSeed(_ number: Int) -> UInt64 {
        GardenRNG.derive(seed, UInt64(number))
    }

    public func makeRound(config: GardenRound.Config = .standard) -> GardenRound {
        GardenRound(seed: roundSeed(roundNumber), config: config)
    }

    public mutating func record(_ result: GardenRoundResult) {
        guard !isComplete else { return }
        results.append(result)
    }

    /// The next set from what is left, or `nil` when nothing is banked.
    public func nextSet() -> GardenSet? {
        guard roundsLeftAfterSet > 0 else { return nil }
        return GardenSet(seed: GardenRNG.derive(seed, 0x5E7), roundsAvailable: roundsLeftAfterSet)
    }
}
