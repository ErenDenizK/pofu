import Foundation

/// The island's four cached blur levels (build spec D10): the composite at radius 0, 2, 6 and
/// 14 pt, blended per pixel by the lens's radius there. Each level's weight is a hat over its
/// neighbours, so the weights sum to 1 and change continuously with the radius: no row ever
/// switches level, which is what keeps band edges out of the picture. `pofuLensLevel` in
/// `WorldShaders.metal` is the shader twin of `weight(level:radius:)`.
public enum BlurLevels {
    /// The levels' radii, in points.
    public static let radii: [Double] = [0, 2, 6, 14]

    /// The radius the levels blend for a lens radius: zero under `ThinLens.skip`, then a ramp
    /// that meets the lens radius at the first level, so skipping never steps.
    public static func effective(_ r: Double) -> Double {
        guard r.isFinite, r > ThinLens.skip else { return 0 }
        let first = radii[1]
        if r >= first { return min(r, ThinLens.cap) }
        return (r - ThinLens.skip) * first / (first - ThinLens.skip)
    }

    /// The weight of `level` (an index into `radii`) for a lens radius `r` (points).
    public static func weight(level: Int, radius r: Double) -> Double {
        guard radii.indices.contains(level) else { return 0 }
        let x = effective(r)
        let at = radii[level]
        if x == at { return 1 }
        if x < at {
            guard level > 0 else { return 1 }
            let below = radii[level - 1]
            return max(0, (x - below) / (at - below))
        }
        guard level < radii.count - 1 else { return 1 }
        let above = radii[level + 1]
        return max(0, (above - x) / (above - at))
    }

    /// The levels a picture needs when its radii span `range`: those with any weight in it.
    public static func levels(spanning range: ClosedRange<Double>) -> [Int] {
        let lo = effective(range.lowerBound), hi = effective(range.upperBound)
        return radii.indices.filter { i in
            let below = i > 0 ? radii[i - 1] : -Double.infinity
            let above = i < radii.count - 1 ? radii[i + 1] : Double.infinity
            return hi > below && lo < above
        }
    }
}
