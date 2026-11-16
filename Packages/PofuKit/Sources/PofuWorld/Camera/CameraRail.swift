import Foundation

/// The three framings of one camera (ADR-0027, which supersedes ADR-0018's names), in rail
/// order: the Map (the tier frame), mid (the whole island with the chrome, Home's stop) and
/// near (the free range in from 1.25 x mid, up to the limit at z 2; it rests at
/// `CameraRail.nearRestScale`).
public enum WorldFraming: Int, CaseIterable, Hashable, Sendable, Comparable {
    case map = 0
    case mid = 1
    case near = 2

    /// The framing's stop on the rail (near's is its limit; it rests at `CameraRail.restZ`).
    public var z: Double {
        Double(rawValue)
    }

    /// Below this rail position a release lands on the Map (ADR-0027).
    public static let mapBelowZ = 0.5
    /// Above this rail position the camera is near and a release stays (1.25 x the mid scale).
    public static let nearAboveZ = 1.12

    /// The framing a rail position belongs to: the Map below 0.5, mid up to 1.12, then near.
    public static func nearest(to z: Double) -> WorldFraming {
        if z < mapBelowZ { return .map }
        if z <= nearAboveZ { return .mid }
        return .near
    }

    public static func < (lhs: WorldFraming, rhs: WorldFraming) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// One framing in, or `nil` at near.
    public var stepIn: WorldFraming? {
        WorldFraming(rawValue: rawValue + 1)
    }

    /// One framing out, or `nil` on the Map.
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

/// The camera's rail (ADR-0027): the Map's tier frame at z 0, mid at z 1 and the near limit
/// at z 2. `ln s` is linear in z on each segment, and the look point and the anchor follow:
/// from the Map to mid both interpolate with the same fraction; past mid the look stays the
/// island's and the anchor eases from mid's row to the near stop's (the screen's middle) as
/// the chrome fades, between 1.05 and 1.25 x the mid scale. Past either end the rail keeps
/// its end look and extends `ln s` along the end segment's slope, where the rubber band lives.
/// Near is free: `CameraRig` adds a look offset there, bounded by `nearBounds`.
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

    // MARK: - The numbers (world-map.json `mid` and `near`, ADR-0027)

    private static let numbers = WorldMap.shipped
    /// The mid stop's island width and box centre row, reference points.
    public static let midFitWidth = numbers?.midFitWidth ?? 378
    public static let midCentreY = numbers?.midCenterY ?? 383
    /// A young island narrower than this share of the width at mid is fitted to it.
    public static let youngFill = 0.72
    /// Near rests here and stops at the limit, in points per unit at the reference width.
    public static let nearRestScale = numbers?.nearRestScale ?? 4.5
    public static let nearLimitScale = numbers?.nearLimitScale ?? 7.4
    /// The chrome fades out between these multiples of the mid scale.
    public static let chromeFade = numbers?.chromeFadeScale ?? 1.05 ... 1.25
    /// The near island box grows by this share before the pan's rubber band starts.
    public static let nearBoundsGrowth = 0.10
    /// The near pan's rubber band, in points.
    public static let nearBand = 30.0

    /// Map, mid and the near limit of the sprite world, fitted by `IslandFraming`.
    public static let referenceStops: [Stop] = {
        let mid = IslandFraming.midStop(width: referenceWidth, height: referenceHeight)
        return [
            IslandFraming.mapStop(width: referenceWidth, height: referenceHeight),
            mid,
            nearStop(mid: mid),
        ]
    }()

    /// The near limit's stop: the island's look at the limit scale, anchored mid-screen.
    public static func nearStop(mid: Stop) -> Stop {
        Stop(scale: nearLimitScale, look: mid.look, anchorY: referenceHeight / 2)
    }

    /// The whole island (the establishing shot) at this viewport.
    public var wholeIslandPose: CameraPose {
        let stop = whole ?? IslandFraming.wholeStop(width: Self.referenceWidth, height: Self.referenceHeight)
        return CameraPose(
            scale: stop.scale * width / Self.referenceWidth,
            look: stop.look,
            anchorY: stop.anchorY * height / Self.referenceHeight
        )
    }

    /// Past the near limit the camera bands up to ×1.12; past the Map down to ×0.85.
    public static let bandIn = log(1.12)
    public static let bandOut = log(1 / 0.85)

    public let width: Double
    public let height: Double
    public let stops: [Stop]
    /// The establishing shot's stop when it is not the sprite island's
    /// (a plate-first home, `HomePlate.wholeStop`).
    public let whole: Stop?
    /// The island's box in world units (the level-10 box); near pans inside it grown 10 %.
    public let island: WorldBox?

    public init(
        width: Double = CameraRail.referenceWidth,
        height: Double = CameraRail.referenceHeight,
        stops: [Stop] = CameraRail.referenceStops,
        whole: Stop? = nil,
        island: WorldBox? = nil
    ) {
        self.width = width > 0 ? width : Self.referenceWidth
        self.height = height > 0 ? height : Self.referenceHeight
        self.stops = stops
        self.whole = whole
        self.island = island
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
        if z < 1 {
            return CameraPose.mix(pose(of: .map), pose(of: .mid), z)
        }
        var pose = pose(of: .mid)
        pose.logScale = logScale(z: z)
        let t = 1 - chromeOpacity(logScale: pose.logScale)
        pose.anchorY += (self.pose(of: .near).anchorY - pose.anchorY) * t
        return pose
    }

    /// `ln s` at `z`, piecewise linear, extrapolated past the ends.
    public func logScale(z: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .mid).logScale
        let l2 = pose(of: .near).logScale
        if z <= 1 {
            return l0 + (l1 - l0) * z
        }
        return l1 + (l2 - l1) * (z - 1)
    }

    /// The rail position of `ln s`: the inverse of `logScale(z:)`.
    public func z(logScale l: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .mid).logScale
        let l2 = pose(of: .near).logScale
        if l <= l1 {
            return (l - l0) / (l1 - l0)
        }
        return 1 + (l - l1) / (l2 - l1)
    }

    /// `dz / d(ln s)` at `z`: converts a pinch's velocity to the rail.
    public func zPerLogScale(at z: Double) -> Double {
        let l0 = pose(of: .map).logScale
        let l1 = pose(of: .mid).logScale
        let l2 = pose(of: .near).logScale
        return z < 1 ? 1 / (l1 - l0) : 1 / (l2 - l1)
    }

    /// Where near rests: `nearRestScale` on this rail (z 1.73 on iPhone 17).
    public var restZ: Double {
        z(logScale: log(Self.nearRestScale * width / Self.referenceWidth))
    }

    /// The rail position a framing lands on: near lands at rest.
    public func z(of framing: WorldFraming) -> Double {
        framing == .near ? restZ : framing.z
    }

    /// The chrome's opacity at `ln s`: 1 at mid, falling to 0 between 1.05 and 1.25 x the
    /// mid scale on a smoothstep. The Map's chrome is not this (it hides by framing).
    public func chromeOpacity(logScale l: Double) -> Double {
        let ratio = exp(l - pose(of: .mid).logScale)
        let lo = Self.chromeFade.lowerBound, hi = Self.chromeFade.upperBound
        let t = min(max((ratio - lo) / (hi - lo), 0), 1)
        return 1 - t * t * (3 - 2 * t)
    }

    /// The fingers' raw `ln s` with the rubber band applied past the ends
    /// (§1.3), in log-scale like Apple's scroll view.
    public func bandedLogScale(raw: Double) -> Double {
        let lo = pose(of: .map).logScale
        let hi = pose(of: .near).logScale
        if raw > hi {
            return hi + Self.rubberBand(raw - hi, limit: Self.bandIn)
        }
        if raw < lo {
            return lo - Self.rubberBand(lo - raw, limit: Self.bandOut)
        }
        return raw
    }

    // MARK: - Near's free range

    /// The box the screen's centre may roam at near: the island's box grown 10 %.
    public var nearBounds: WorldBox? {
        guard let box = island ?? Optional(IslandFraming.islandBox) else { return nil }
        let gx = box.width * Self.nearBoundsGrowth / 2, gy = box.height * Self.nearBoundsGrowth / 2
        return WorldBox(minX: box.minX - gx, minY: box.minY - gy, maxX: box.maxX + gx, maxY: box.maxY + gy)
    }

    /// The look offset (world units, added to the rail's look) that keeps the screen's centre
    /// inside `nearBounds` at rail position `z`, per axis: the hard range before the band.
    public func freeRange(z: Double) -> (x: ClosedRange<Double>, y: ClosedRange<Double>)? {
        guard let bounds = nearBounds else { return nil }
        let pose = pose(z: z)
        let s = max(pose.scale, 1e-6)
        // The screen's centre is at look + ((0, height / 2 - anchorY) / s).
        let cy = (height / 2 - pose.anchorY) / s
        let x = (bounds.minX - pose.lookX) ... max(bounds.minX - pose.lookX, bounds.maxX - pose.lookX)
        let yLo = bounds.minY - pose.lookY - cy
        let y = yLo ... max(yLo, bounds.maxY - pose.lookY - cy)
        return (x, y)
    }

    /// A look offset with the near rubber band applied past `freeRange` (30 pt, in points).
    public func bandedFree(x: Double, y: Double, z: Double) -> (x: Double, y: Double) {
        guard let range = freeRange(z: z) else { return (x, y) }
        let s = max(pose(z: z).scale, 1e-6)
        func band(_ v: Double, _ r: ClosedRange<Double>) -> Double {
            if v > r.upperBound { return r.upperBound + Self.rubberBand((v - r.upperBound) * s, limit: Self.nearBand) / s }
            if v < r.lowerBound { return r.lowerBound - Self.rubberBand((r.lowerBound - v) * s, limit: Self.nearBand) / s }
            return v
        }
        return (band(x, range.x), band(y, range.y))
    }

    /// A look offset clamped into `freeRange` at `z`.
    public func clampedFree(x: Double, y: Double, z: Double) -> (x: Double, y: Double) {
        guard let range = freeRange(z: z) else { return (x, y) }
        return (min(max(x, range.x.lowerBound), range.x.upperBound), min(max(y, range.y.lowerBound), range.y.upperBound))
    }

    /// The look offset that puts `world` under screen point (`x`, `y`) at rail position `z`.
    public func free(keeping world: WorldPoint, atScreenX x: Double, y: Double, z: Double) -> (x: Double, y: Double) {
        let pose = pose(z: z)
        let s = max(pose.scale, 1e-6)
        return (world.x - pose.lookX - (x - width / 2) / s, world.y - pose.lookY - (y - pose.anchorY) / s)
    }

    /// Apple's scroll-view band: `(1 − 1 / (0.55·x / D + 1)) · D`. It
    /// tracks 0.55:1 at first and never reaches `limit`.
    public static func rubberBand(_ overshoot: Double, limit: Double) -> Double {
        guard overshoot > 0, limit > 0 else { return 0 }
        return (1 - 1 / (0.55 * overshoot / limit + 1)) * limit
    }
}
