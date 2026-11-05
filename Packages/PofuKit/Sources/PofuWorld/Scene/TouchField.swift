import Foundation

/// Brushing (experience v1 §1.3): a dragging finger also touches the
/// island. The finger's path, unprojected into the world, gives every
/// touchable prop within `reach` units an impulse; the prop reads
/// `sway(of:at:)` as a rotation about its base. Passive: it never fights
/// the pan, and taps stay the only verbs.
///
/// Pure and time-explicit (seconds), so it is tested on any platform. It
/// keeps at most `capacity` impulses, each alive for `lifetime` seconds.
public struct TouchField: Sendable {
    public struct Impulse: Hashable, Sendable {
        public var prop: String
        /// When it began, in seconds.
        public var t0: Double
        /// Peak sway in degrees.
        public var amplitude: Double
        /// -1 to the left of the finger's travel, +1 to the right.
        public var direction: Double
    }

    /// How close the finger passes, in world units.
    public static let reach = 24.0
    public static let capacity = 16
    /// How long an impulse lives, in seconds.
    public static let lifetime = 1.2
    /// The sway's frequency, in hertz.
    public static let frequency = 3.2
    /// The largest sway, in degrees.
    public static let peakDegrees = 7.0
    /// Brushing needs the Island framing or closer.
    public static let minimumZ = 0.8

    public private(set) var impulses: [Impulse] = []
    private var last: WorldPoint?

    public init() {}

    /// The finger lifted: the next brush starts a new stroke.
    public mutating func endStroke() {
        last = nil
    }

    /// The finger is at `point` in the world at time `t`; `props` are the
    /// touchable props (id and base). Props within `reach` of the segment
    /// from the previous point get an impulse.
    public mutating func brush(at point: WorldPoint, t: Double, props: [(id: String, base: WorldPoint)]) {
        defer { last = point }
        prune(at: t)
        let from = last ?? point
        let dx = point.x - from.x
        for prop in props {
            let distance = Self.distance(from: prop.base, toSegment: from, point)
            guard distance <= Self.reach else { continue }
            // Stronger the closer the finger passes.
            let amplitude = Self.peakDegrees * (1 - 0.6 * distance / Self.reach)
            let direction: Double = dx == 0 ? (prop.base.x >= point.x ? 1 : -1) : (dx > 0 ? 1 : -1)
            // A prop already swaying is retriggered, not stacked.
            impulses.removeAll { $0.prop == prop.id }
            impulses.append(Impulse(prop: prop.id, t0: t, amplitude: amplitude, direction: direction))
        }
        if impulses.count > Self.capacity {
            impulses.removeFirst(impulses.count - Self.capacity)
        }
    }

    /// Drops the impulses that have run out.
    public mutating func prune(at t: Double) {
        impulses.removeAll { t - $0.t0 >= Self.lifetime }
    }

    /// Whether any impulse is alive at `t`: the scene draws frames until
    /// none is.
    public func isActive(at t: Double) -> Bool {
        impulses.contains { t - $0.t0 < Self.lifetime }
    }

    /// The prop's sway in degrees at `t`: a damped swing about its base
    /// that is exactly zero once the impulse has lived `lifetime`.
    public func sway(of prop: String, at t: Double) -> Double {
        var total = 0.0
        for impulse in impulses where impulse.prop == prop {
            let age = t - impulse.t0
            guard age >= 0, age < Self.lifetime else { continue }
            let envelope = pow(1 - age / Self.lifetime, 2)
            total += impulse.direction * impulse.amplitude * envelope * cos(2 * .pi * Self.frequency * age)
        }
        return total
    }

    /// The distance from `p` to the segment `a`–`b`.
    static func distance(from p: WorldPoint, toSegment a: WorldPoint, _ b: WorldPoint) -> Double {
        let abx = b.x - a.x, aby = b.y - a.y
        let lengthSquared = abx * abx + aby * aby
        var t = 0.0
        if lengthSquared > 1e-12 {
            t = min(max(((p.x - a.x) * abx + (p.y - a.y) * aby) / lengthSquared, 0), 1)
        }
        let cx = a.x + abx * t, cy = a.y + aby * t
        let dx = p.x - cx, dy = p.y - cy
        return (dx * dx + dy * dy).squareRoot()
    }
}
