import Foundation

/// The three designed framings of one world (ADR-0018), in rail order.
public enum WorldFraming: Int, CaseIterable, Hashable, Sendable, Comparable {
    case map = 0
    case island = 1
    case home = 2

    /// The framing's position on the rail.
    public var z: Double {
        Double(rawValue)
    }

    /// The nearest framing to a rail position.
    public static func nearest(to z: Double) -> WorldFraming {
        let index = Int(min(max(z, 0), 2).rounded())
        return WorldFraming(rawValue: index) ?? .island
    }

    public static func < (lhs: WorldFraming, rhs: WorldFraming) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// One framing in (toward Home), or `nil` at Home.
    public var stepIn: WorldFraming? {
        WorldFraming(rawValue: rawValue + 1)
    }

    /// One framing out (toward the Map), or `nil` on the Map.
    public var stepOut: WorldFraming? {
        WorldFraming(rawValue: rawValue - 1)
    }
}

/// Where the camera is: its scale (as a natural log, so interpolation
/// feels even), the world point it looks at, and the screen row where that
/// point sits. The point sits in the horizontal middle of the screen.
public struct CameraPose: Hashable, Sendable {
    public var logScale: Double
    public var lookX: Double
    public var lookY: Double
    /// Screen points from the top.
    public var anchorY: Double

    public init(logScale: Double, lookX: Double, lookY: Double, anchorY: Double) {
        self.logScale = logScale
        self.lookX = lookX
        self.lookY = lookY
        self.anchorY = anchorY
    }

    public init(scale: Double, look: WorldPoint, anchorY: Double) {
        self.init(logScale: log(max(scale, 1e-6)), lookX: look.x, lookY: look.y, anchorY: anchorY)
    }

    /// Points per world unit.
    public var scale: Double {
        exp(logScale)
    }

    /// Every component interpolated linearly (log-scale for the scale).
    public static func mix(_ a: CameraPose, _ b: CameraPose, _ t: Double) -> CameraPose {
        CameraPose(
            logScale: a.logScale + (b.logScale - a.logScale) * t,
            lookX: a.lookX + (b.lookX - a.lookX) * t,
            lookY: a.lookY + (b.lookY - a.lookY) * t,
            anchorY: a.anchorY + (b.anchorY - a.anchorY) * t
        )
    }

    /// The screen point of a world point, in a viewport `width` wide.
    public func project(_ point: WorldPoint, width: Double) -> (x: Double, y: Double) {
        let s = scale
        return (width / 2 + (point.x - lookX) * s, anchorY + (point.y - lookY) * s)
    }

    /// The world point under a screen point.
    public func unproject(x: Double, y: Double, width: Double) -> WorldPoint {
        let s = scale
        return WorldPoint(x: lookX + (x - width / 2) / s, y: lookY + (y - anchorY) / s)
    }
}

/// The camera's rail through Map (z 0), Island (z 1) and Home (z 2)
/// (interaction spec §1.2). Between framings `ln s` and the look point
/// interpolate linearly with the same fraction. Past either end the rail
/// keeps its end framing's look point and extends `ln s` along the end
/// segment's slope, which is where the rubber band lives.
public struct CameraRail: Hashable, Sendable {
    /// A framing in reference points (iPhone 17: 402 × 874).
    public struct Stop: Hashable, Sendable {
        public var scale: Double
        public var look: WorldPoint
        public var anchorY: Double

        public init(scale: Double, look: WorldPoint, anchorY: Double) {
            self.scale = scale
            self.look = look
            self.anchorY = anchorY
        }
    }

    public static let referenceWidth = 402.0
    public static let referenceHeight = 874.0

    /// Map, Island, Home, from design review 01 (option B): Pofu is
    /// 154 pt, 38 % of the width, at Home (ADR-0018).
    public static let referenceStops: [Stop] = [
        Stop(scale: 0.46, look: WorldPoint(x: 0, y: -80), anchorY: 430),
        Stop(scale: 1.06, look: WorldPoint(x: 0, y: 40), anchorY: 470),
        Stop(scale: 2.40, look: IslandLayout.pofu, anchorY: 600),
    ]

    /// Past Home the camera bands up to ×1.25; past the Map down to ×0.8.
    public static let bandIn = log(1.25)
    public static let bandOut = log(1 / 0.8)

    public let width: Double
    public let height: Double
    public let stops: [Stop]

    public init(width: Double = CameraRail.referenceWidth, height: Double = CameraRail.referenceHeight, stops: [Stop] = CameraRail.referenceStops) {
        self.width = width > 0 ? width : Self.referenceWidth
        self.height = height > 0 ? height : Self.referenceHeight
        self.stops = stops
    }

    /// Scales follow the width; screen rows follow the height.
    public func pose(of framing: WorldFraming) -> CameraPose {
        let stop = stops[framing.rawValue]
        return CameraPose(
            scale: stop.scale * width / Self.referenceWidth,
            look: stop.look,
            anchorY: stop.anchorY * height / Self.referenceHeight
        )
    }

    /// The pose at rail position `z`; `z` may run past either end.
    public func pose(z: Double) -> CameraPose {
        if z <= 0 {
            var pose = pose(of: .map)
            pose.logScale = logScale(z: z)
            return pose
        }
        if z >= 2 {
            var pose = pose(of: .home)
            pose.logScale = logScale(z: z)
            return pose
        }
        let lower = WorldFraming(rawValue: Int(z.rounded(.down))) ?? .map
        let upper = lower.stepIn ?? .home
        return CameraPose.mix(pose(of: lower), pose(of: upper), z - lower.z)
    }

    /// `ln s` at `z`, piecewise linear, extrapolated past the ends.
    public func logScale(z: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .island).logScale
        let l2 = pose(of: .home).logScale
        if z <= 1 {
            return l0 + (l1 - l0) * z
        }
        return l1 + (l2 - l1) * (z - 1)
    }

    /// The rail position of `ln s`: the inverse of `logScale(z:)`.
    public func z(logScale l: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .island).logScale
        let l2 = pose(of: .home).logScale
        if l <= l1 {
            return (l - l0) / (l1 - l0)
        }
        return 1 + (l - l1) / (l2 - l1)
    }

    /// `dz / d(ln s)` at `z`: converts a pinch's velocity to the rail.
    public func zPerLogScale(at z: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .island).logScale
        let l2 = pose(of: .home).logScale
        return z < 1 ? 1 / (l1 - l0) : 1 / (l2 - l1)
    }

    /// The fingers' raw `ln s` with the rubber band applied past the ends
    /// (§1.3), in log-scale like Apple's scroll view.
    public func bandedLogScale(raw: Double) -> Double {
        let lo = pose(of: .map).logScale
        let hi = pose(of: .home).logScale
        if raw > hi {
            return hi + Self.rubberBand(raw - hi, limit: Self.bandIn)
        }
        if raw < lo {
            return lo - Self.rubberBand(lo - raw, limit: Self.bandOut)
        }
        return raw
    }

    /// Apple's scroll-view band: `(1 − 1 / (0.55·x / D + 1)) · D`. It
    /// tracks 0.55:1 at first and never reaches `limit`.
    public static func rubberBand(_ overshoot: Double, limit: Double) -> Double {
        guard overshoot > 0, limit > 0 else { return 0 }
        return (1 - 1 / (0.55 * overshoot / limit + 1)) * limit
    }
}
