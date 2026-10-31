import Foundation

/// Squash and stretch for a soft body standing on the ground.
///
/// `squash` is negative when Pofu is squashed (shorter, wider) and positive
/// when stretched. Scales are applied with the anchor at the bottom center,
/// so the feet stay planted. Area is preserved up to `preservation`:
/// `scaleX = (1 + squash) ^ -preservation`; 1 keeps the silhouette's area
/// exactly, slightly less reads softer on a round body.
public enum SquashModel {
    /// The squash range the art survives. Past roughly ±25% the painted fur
    /// visibly smears.
    public static let range: ClosedRange<Double> = -0.24...0.2

    /// Default area preservation.
    public static let preservation = 0.75

    /// Scales for a squash amount, clamped to `range`.
    public static func scales(squash: Double, preservation: Double = preservation) -> (x: Double, y: Double) {
        let s = squash.isNaN ? 0 : min(max(squash, range.lowerBound), range.upperBound)
        let y = 1 + s
        return (x: pow(y, -preservation), y: y)
    }

    /// The slump of a low-vitality body: shorter and wider, never more than
    /// 7% shorter. `vitality` is in `0...1`.
    public static func slump(vitality: Double) -> (x: Double, y: Double) {
        let v = clampUnit(vitality)
        return (x: lerp(1.035, 1, v), y: lerp(0.93, 1, v))
    }
}
