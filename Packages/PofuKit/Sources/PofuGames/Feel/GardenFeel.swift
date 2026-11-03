import Foundation
import PofuTuning

/// Easing curves for the game layer, pure so they are tested and so the
/// scene's SpriteKit timing functions and any SwiftUI twin agree.
///
/// | Curve | Used for | Why |
/// |---|---|---|
/// | `outCubic` | snap to the cell, tray return's travel, seed arcs' scale | Fast start, soft landing: the piece "wants" to go there |
/// | `outBack(s)` | pick-up (s 1.2), bloom pop (s 1.7 → 2.6 with the combo), tray deal (s 1.4) | A small overshoot reads as springy clay, not as a UI slide |
/// | `inQuad` | seeds falling into Pofu's cheeks | Accelerates into the mouth: a gulp, not a float |
/// | `inOutSine` | idle breathing, glow pulse | No corners, so loops never tick |
/// | `squash(t)` | placement squash, the land after a hop | 1 → 1.14 × 0.86 → 0.96 × 1.04 → 1: one decaying wobble |
public enum GameEasing {
    public static func linear(_ t: Double) -> Double { clamp(t) }

    public static func outCubic(_ t: Double) -> Double {
        let u = 1 - clamp(t)
        return 1 - u * u * u
    }

    public static func inQuad(_ t: Double) -> Double {
        let t = clamp(t)
        return t * t
    }

    public static func inOutSine(_ t: Double) -> Double {
        -(cos(Double.pi * clamp(t)) - 1) / 2
    }

    /// Overshoots past 1 by about `s * 0.1` near t ≈ 0.6, then settles.
    public static func outBack(_ t: Double, overshoot s: Double = 1.70158) -> Double {
        let u = clamp(t) - 1
        return 1 + (s + 1) * u * u * u + s * u * u
    }

    /// The horizontal stretch of a squash at time `t` (vertical is its
    /// reciprocal-ish twin, `2 - x`), one decaying wobble.
    public static func squash(_ t: Double, amount: Double = 0.14) -> Double {
        let t = clamp(t)
        return 1 + amount * sin(t * Double.pi * 2.2) * exp(-4.2 * t)
    }

    static func clamp(_ t: Double) -> Double { min(1, max(0, t)) }
}

/// The screen-shake budget: tiny, rare, earned.
///
/// Shake only for a double bloom or a combo of three; never for a single
/// line, never twice within `cooldown`, never above `maximum` points, and
/// never with Reduce Motion. Each request returns the amplitude allowed
/// (0 for none).
public struct ShakeBudget: Sendable, Equatable {
    public var maximum: Double
    public var cooldown: TimeInterval
    public private(set) var lastShake: TimeInterval?

    public init(maximum: Double = 4, cooldown: TimeInterval = 1.2) {
        self.maximum = maximum
        self.cooldown = cooldown
    }

    public mutating func request(lines: Int, combo: Int, at time: TimeInterval, reduceMotion: Bool) -> Double {
        guard !reduceMotion, lines >= 2 || combo >= 3 else { return 0 }
        if let lastShake, time - lastShake < cooldown { return 0 }
        lastShake = time
        return min(maximum, 1.5 + Double(lines - 1) * 1.0 + Double(max(0, combo - 2)) * 0.5)
    }
}

/// Every number the garden's feel is tuned with. The values are data
/// (`TuningValues.Garden` in `PofuTuning`'s `tuning.json`), so the tuning lab
/// panel in Rehearsal mode changes them live on the phone and exports the
/// result; read them as properties (`feel.bloomPop`). Durations are in
/// seconds, lengths in cells unless named.
@dynamicMemberLookup
public struct GardenFeel: Sendable, Equatable {
    public var values: TuningValues.Garden

    public init(_ values: TuningValues.Garden = TuningValues.defaults.garden) {
        self.values = values
    }

    /// The bundled defaults.
    public static var standard: GardenFeel { GardenFeel() }

    public subscript<T>(dynamicMember keyPath: KeyPath<TuningValues.Garden, T>) -> T {
        values[keyPath: keyPath]
    }

    /// Blooms start this long after the plot lands.
    public static let bloomDelay = 0.06
    /// Seeds leave a little apart.
    public static let seedStagger = 0.02
    /// Haptic ticks while dragging are rationed: at most one per this long.
    public static let tickInterval = 0.06

    /// The bloom pop's overshoot grows with the combo, at most 1.1 above
    /// the tuned base.
    public func bloomOvershoot(combo: Int) -> Double {
        values.bloomOvershoot + min(1.1, 0.3 * Double(max(0, combo - 1)))
    }

    /// Petals per bloomed cell grow with the combo, capped.
    public func petals(combo: Int) -> Int {
        min(7, 3 + max(0, combo - 1))
    }

    /// Haptic intensity of a bloom (0...1): the tuned base, stronger with
    /// more lines and a longer combo.
    public func bloomHaptic(lines: Int, combo: Int) -> Double {
        min(1, values.hapticBloom + 0.15 * Double(max(0, lines - 1)) + 0.08 * Double(max(0, combo - 1)))
    }

    /// How many of a bloom's `cells` release a seed: `seedsPerLine` per
    /// line, spread evenly, at least one.
    public func seedStride(cells: Int, lines: Int) -> Int {
        let seeds = max(1, Int(values.seedsPerLine.rounded()) * max(1, lines))
        return max(1, cells / seeds)
    }
}
