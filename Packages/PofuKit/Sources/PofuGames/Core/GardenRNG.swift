/// A small, seeded, deterministic random number generator (SplitMix64).
///
/// Every random choice in a round goes through one of these, seeded from
/// the set, so a round replays exactly from its seed: tests can assert on
/// trays, and a bug report can name the seed. Not for anything secret.
public struct GardenRNG: RandomNumberGenerator, Sendable, Equatable {
    public private(set) var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A uniform integer in `0..<bound`, without modulo bias.
    public mutating func int(below bound: Int) -> Int {
        precondition(bound > 0, "bound must be positive")
        return Int(next(upperBound: UInt64(bound)))
    }

    /// A uniform value in `0..<1`.
    public mutating func unit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    /// An index into `weights`, chosen in proportion to each weight.
    /// Zero weights are never chosen; all-zero weights choose nothing.
    public mutating func weightedIndex(_ weights: [Int]) -> Int? {
        let total = weights.reduce(0) { $0 + max(0, $1) }
        guard total > 0 else { return nil }
        var pick = int(below: total)
        for (index, weight) in weights.enumerated() where weight > 0 {
            if pick < weight { return index }
            pick -= weight
        }
        return nil
    }

    /// A seed derived from this one and a salt, for sub-streams (one per
    /// round of a set) that do not shift when another stream is used more.
    public static func derive(_ seed: UInt64, _ salt: UInt64) -> UInt64 {
        var rng = GardenRNG(seed: seed ^ (salt &* 0xD1B5_4A32_D192_ED03))
        return rng.next()
    }
}
