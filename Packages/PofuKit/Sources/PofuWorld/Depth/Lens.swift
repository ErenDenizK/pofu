import Foundation

/// The depth lens (interaction spec §12.1): every world object has a
/// depth, larger is nearer, and its blur grows with its distance from the
/// focus plane, in front and behind alike:
///
///     b = clamp((|d − focus| − slab) · gain, 0, 2)
///
/// `slab` is half the in-focus thickness and `gain` is 1 / range; a gain of
/// 0 keeps everything sharp (the map).
public struct Lens: Hashable, Sendable {
    public var focus: Double
    public var slab: Double
    public var gain: Double

    public init(focus: Double, slab: Double, gain: Double) {
        self.focus = focus
        self.slab = slab
        self.gain = gain
    }

    public init(focus: Double, slab: Double, range: Double) {
        self.init(focus: focus, slab: slab, gain: range > 0 && range.isFinite ? 1 / range : 0)
    }

    /// 0 sharp, 1 soft, 2 deep; continuous in between.
    public func blurLevel(depth: Double) -> Double {
        let level = (abs(depth - focus) - slab) * gain
        guard level.isFinite else { return 0 }
        return min(max(level, 0), 2)
    }

    public static func mix(_ a: Lens, _ b: Lens, _ t: Double) -> Lens {
        Lens(
            focus: a.focus + (b.focus - a.focus) * t,
            slab: a.slab + (b.slab - a.slab) * t,
            gain: a.gain + (b.gain - a.gain) * t
        )
    }

    // MARK: - The recommended lenses (§12.1), in PofuWorld's depth units

    /// Home: shallow, on Pofu. The garden beside him is barely soft; the
    /// back of the lawn and the island's body are deep.
    public static let home = Lens(focus: IslandLayout.depth(ofY: IslandLayout.pofu.y), slab: 10, range: 50)
    /// Island: medium and subtle; only the island's front body softens.
    public static let island = Lens(focus: -10, slab: 50, range: 240)
    /// Map: everything sharp.
    public static let map = Lens(focus: -10, slab: 50, gain: 0)

    /// A station's plane is sharp, so its neighbours on the same row stay
    /// sharp too.
    public static func station(depth: Double) -> Lens {
        Lens(focus: depth, slab: 8, range: 60)
    }

    /// The tightest focus: a portrait.
    public static func resident(depth: Double) -> Lens {
        Lens(focus: depth, slab: 6, range: 48)
    }

    /// The lens along the camera rail, so a pinch racks focus continuously.
    public static func rail(z: Double) -> Lens {
        // The framings themselves are exact.
        if z >= 2 { return .home }
        if z <= 0 { return .map }
        if z == 1 { return .island }
        if z > 1 {
            return mix(.island, .home, min(z - 1, 1))
        }
        return mix(.map, .island, max(z, 0))
    }
}

/// The opacities of the three stacked variants for a blur level
/// (interaction spec §12.1): the sharp image fades out over the soft one
/// between 0 and 1, and the soft one is fully in by 0.25 so edges never
/// thin out; then the soft one fades over the deep one between 1 and 2.
public struct DepthWeights: Hashable, Sendable {
    public var sharp: Double
    public var soft: Double
    public var deep: Double

    public init(level: Double) {
        let b = level.isFinite ? min(max(level, 0), 2) : 0
        if b <= 1 {
            sharp = 1 - b
            soft = min(b * 4, 1)
            deep = 0
        } else {
            sharp = 0
            soft = 2 - b
            deep = min((b - 1) * 4, 1)
        }
    }

    public func weight(_ variant: DepthVariant) -> Double {
        switch variant {
        case .sharp: sharp
        case .soft: soft
        case .deep: deep
        }
    }

    /// Below this a layer leaves the render tree: invisible is not free.
    public static let visibleThreshold = 0.004
}
