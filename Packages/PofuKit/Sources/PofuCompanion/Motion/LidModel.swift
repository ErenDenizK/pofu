import Foundation

/// Lid lines for one eye, in the eye's normalized space: x and y in
/// `-1...1` across the eye ellipse, y pointing down.
///
/// The upper lid comes down to meet a soft "smile" closing line (blinks,
/// sleepiness), tilted toward the outer corner when sad. The lower lid
/// rises to a thin arch just under the top rim when happy, which leaves a
/// ^-shaped sliver of eye. Same math as the WebGL prototype.
public struct LidModel: Hashable, Sendable {
    /// Upper-lid closure in `0...1`.
    public var closure: Double
    /// Happy squint in `0...1`.
    public var happiness: Double
    /// Sad droop in `0...1`.
    public var sadness: Double
    /// -1 for the left eye, +1 for the right (the outer corner's side).
    public var outerSide: Double

    public init(closure: Double, happiness: Double, sadness: Double, outerSide: Double) {
        self.closure = clampUnit(closure)
        self.happiness = clampUnit(happiness)
        self.sadness = clampUnit(sadness)
        self.outerSide = outerSide < 0 ? -1 : 1
    }

    /// Half the eye's height at `x`.
    public static func rim(_ x: Double) -> Double {
        let c = min(max(x, -1), 1)
        return (1 - c * c).squareRoot()
    }

    static func closingLine(_ x: Double) -> Double {
        0.28 + 0.22 * (1 - x * x)
    }

    /// The upper lid's edge at `x`; the lid covers everything above it.
    public func upper(_ x: Double) -> Double {
        let s = Self.rim(x)
        let droop = sadness * closure * 0.55 * (x * outerSide + 0.15)
        return lerp(-s, Self.closingLine(x), closure) + droop
    }

    /// The lower lid's edge at `x`; the lid covers everything below it.
    public func lower(_ x: Double) -> Double {
        let s = Self.rim(x)
        let blink = lerp(s, Self.closingLine(x), closure * closure * closure)
        return lerp(blink, -s + 0.42, happiness)
    }

    /// Where the lids meet when they overlap, else `nil` (the eye is open
    /// at `x`).
    public func meeting(_ x: Double) -> Double? {
        let u = upper(x)
        let l = lower(x)
        return l - u < 0.03 ? (u + l) / 2 : nil
    }

    /// The visible band of the eye at `x`, clamped to the rim, or `nil`
    /// where the eye is shut.
    public func openBand(_ x: Double) -> ClosedRange<Double>? {
        guard meeting(x) == nil else { return nil }
        let s = Self.rim(x)
        let top = min(max(upper(x), -s), s)
        let bottom = min(max(lower(x), -s), s)
        return top < bottom ? top...bottom : nil
    }
}
