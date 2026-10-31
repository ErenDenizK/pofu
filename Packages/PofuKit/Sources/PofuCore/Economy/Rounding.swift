/// Tolerant rounding from real-valued rule results to whole energy units.
///
/// Multipliers are configured as `Double` so they stay readable when tuned
/// (`1.25`, not `125` per mille). Binary floating point cannot represent most
/// decimal fractions exactly, so a product that is mathematically an integer
/// can land a hair below it (`1.15 * 100 == 114.99999999999999`). Rounding
/// with a small tolerance keeps such results on the integer they mean.
enum Rounding {
    /// Far below any meaningful fraction of an energy unit, far above the
    /// error of a few floating-point multiplications at realistic magnitudes.
    static let tolerance = 1e-9

    /// Rounds down, treating values within `tolerance` below an integer as
    /// that integer. Used for earning: the user never receives a fraction.
    static func down(_ value: Double) -> Int {
        saturatingInt((value + tolerance).rounded(.down))
    }

    /// Rounds up, treating values within `tolerance` above an integer as
    /// that integer. Used for prices: a fraction of a unit costs a full unit.
    static func up(_ value: Double) -> Int {
        saturatingInt((value - tolerance).rounded(.up))
    }

    /// Converts an already-integral `Double` to `Int` without trapping.
    /// NaN maps to zero; out-of-range values saturate.
    static func saturatingInt(_ value: Double) -> Int {
        if value.isNaN { return 0 }
        if value >= Double(Int.max) { return Int.max }
        if value <= Double(Int.min) { return Int.min }
        return Int(value)
    }

    /// Clamps to `0...1`, mapping NaN to zero.
    static func unitInterval(_ value: Double) -> Double {
        if value.isNaN { return 0 }
        return min(max(value, 0), 1)
    }
}
