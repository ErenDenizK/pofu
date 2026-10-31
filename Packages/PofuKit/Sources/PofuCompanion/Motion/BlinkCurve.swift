import Foundation

/// The lid closure of a single blink over time.
///
/// Real blinks are asymmetric: the lid drops fast, holds for an instant,
/// and lifts more slowly. Durations follow human blinks scaled slightly
/// slower for a small, soft creature.
public enum BlinkCurve {
    public static let closeDuration = 0.07
    public static let holdDuration = 0.04
    public static let openDuration = 0.13

    public static var totalDuration: Double {
        closeDuration + holdDuration + openDuration
    }

    /// Lid closure in `0...1` (1 = closed) `elapsed` seconds into a blink.
    public static func closure(elapsed: Double) -> Double {
        guard elapsed.isFinite, elapsed >= 0 else { return 0 }
        if elapsed < closeDuration {
            return smoothstep(0, closeDuration, elapsed)
        }
        if elapsed < closeDuration + holdDuration {
            return 1
        }
        if elapsed < totalDuration {
            return 1 - smoothstep(closeDuration + holdDuration, totalDuration, elapsed)
        }
        return 0
    }
}

/// A small deterministic random source (SplitMix64), so idle behavior is
/// reproducible in tests and previews.
public struct CompanionRandom: Sendable, Hashable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    /// A uniformly distributed value in `0..<1`.
    public mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }

    /// A uniformly distributed value in `range`.
    public mutating func next(in range: ClosedRange<Double>) -> Double {
        lerp(range.lowerBound, range.upperBound, next())
    }
}
