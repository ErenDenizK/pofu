import Foundation

/// Graphics spike: depth of field from a per-pixel depth, not per layer.
///
/// Today `Lens` blurs whole layers: a plate band, a station, a resident.
/// Here every pixel has a depth: the ground plane's from its screen row
/// (through the camera pose, `IslandLayout.depth(ofY:)`) and each object's
/// from its base row, constant over the object. A focus plane sits at the
/// focal object's depth; the blur radius grows with the distance from it,
/// in front and behind alike, so the ground around the focused object is
/// sharp and recedes gradually (tilt-shift-like), and objects at the focus
/// depth stay sharp. These functions are the pure twin of the
/// `pofuDepthBlur` shader and of the depth map the scene renders.
public struct DepthOfField: Hashable, Sendable {
    /// The depth map encodes this range in 8 bits: 0 is `farthest` (sky),
    /// 1 is `nearest`.
    public static let farthest = -400.0
    public static let nearest = 200.0

    /// The focus plane, in `IslandLayout` depth units (larger is nearer).
    public var focus: Double
    /// Half the in-focus thickness.
    public var slab: Double
    /// The distance past the slab at which the blur is full.
    public var range: Double
    /// The largest blur radius, in screen points.
    public var maxRadius: Double
    /// Behind the focus plane blurs a little more than in front of it.
    public var behindBias: Double

    public init(focus: Double, slab: Double = 12, range: Double = 120, maxRadius: Double = 9, behindBias: Double = 1.15) {
        self.focus = focus
        self.slab = slab
        self.range = range
        self.maxRadius = maxRadius
        self.behindBias = behindBias
    }

    /// The blur radius, in points, of a pixel at `depth`: zero inside the
    /// slab, then a smoothstep to `maxRadius` over `range`.
    public func blurRadius(depth: Double) -> Double {
        guard depth.isFinite else { return 0 }
        let delta = depth - focus
        // The slab is the in-focus thickness either side; the bias only
        // speeds the growth behind it.
        let excess = max(abs(delta) - slab, 0) * (delta < 0 ? behindBias : 1)
        let t = min(max(excess / max(range, 1e-6), 0), 1)
        return maxRadius * t * t * (3 - 2 * t)
    }

    // MARK: Depth mapping

    /// The depth of the ground at world row `worldY`.
    public static func groundDepth(worldY: Double) -> Double {
        IslandLayout.depth(ofY: worldY)
    }

    /// The depth of the ground under screen row `screenY` for a camera
    /// looking at `pose`, shifted by `offsetY` (the peek). Inverts
    /// `CameraPose.project`.
    public static func groundDepth(screenY: Double, pose: CameraPose, offsetY: Double = 0) -> Double {
        let worldY = pose.lookY + (screenY - offsetY - pose.anchorY) / pose.scale
        return groundDepth(worldY: worldY)
    }

    /// The screen row where the ground has `depth`; the inverse of
    /// `groundDepth(screenY:pose:offsetY:)`.
    public static func screenY(forDepth depth: Double, pose: CameraPose, offsetY: Double = 0) -> Double {
        let worldY = depth / IslandLayout.depthPerY
        return pose.anchorY + offsetY + (worldY - pose.lookY) * pose.scale
    }

    /// Depth to the map's 0...1 encoding (clamped).
    public static func encoded(_ depth: Double) -> Double {
        min(max((depth - farthest) / (nearest - farthest), 0), 1)
    }

    public static func decoded(_ value: Double) -> Double {
        farthest + value * (nearest - farthest)
    }

    /// This field in the map's 0...1 units, as the shader takes it: focus,
    /// slab and range, plus the radius in points.
    public var shaderParameters: (focus: Double, slab: Double, range: Double, maxRadius: Double) {
        let span = Self.nearest - Self.farthest
        return (Self.encoded(focus), slab / span, range / span, maxRadius)
    }
}
