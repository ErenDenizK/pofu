import Foundation

/// The world's one lens (world-presentation v2 §5, build spec WP11): a thin lens focused on a
/// plane, with its constants folded into the aperture `N` and 1375.
///
///     D     = 1375 / s                                          the subject distance, world units
///     delta = (rowFocus - row) * unitsPerPixel * cos(e) / sin(e)  behind (+) or in front (-) of the plane
///     r     = N * s * |delta| / (D + delta)                     the blur radius in points, capped at 14
///
/// `s` is the camera's scale (points per world unit), `row` a plate row (the foot of a standing
/// thing, a ground pixel's own row, the lip's row for the earth face) and `e` the painting's
/// camera elevation. The nearer the camera, the thinner the sharp zone; at mid the whole island
/// is inside it; two things on one row are sharp together. Sharp is r ≤ 0.5 pt; under 0.35 pt a
/// layer skips the blur.
public struct ThinLens: Hashable, Sendable {
    /// The camera's scale, points per world unit.
    public var scale: Double
    /// The aperture: the shot's `N` (`ThinLens.Shots`).
    public var aperture: Double
    /// The focal plane's plate row.
    public var focusRow: Double
    /// World units per plate pixel (`HomePlate.unitsPerPixel`).
    public var unitsPerPixel: Double
    /// The painting's camera elevation, in degrees (`plate-home.json` `camera.elevationDeg`).
    public var elevationDeg: Double

    /// Blur never grows past this, in points.
    public static let cap = 14.0
    /// In front of the focal plane blur stops at the 6 pt level: a tilt-shift wants a soft front,
    /// not a smear (the thin lens alone puts everything about 115 rows in front of Pofu at 14 pt,
    /// and a wheel there read as a grey blob). The 14 pt level is the back's and the sky's.
    public static let frontCap = 6.0
    /// At or under this radius a thing reads as sharp.
    public static let sharp = 0.5
    /// Under this radius a layer skips its blur altogether.
    public static let skip = 0.35
    /// `D = distanceConstant / s`.
    public static let distanceConstant = 1375.0

    public init(scale: Double, aperture: Double, focusRow: Double, unitsPerPixel: Double, elevationDeg: Double = 10.5) {
        self.scale = scale
        self.aperture = aperture
        self.focusRow = focusRow
        self.unitsPerPixel = unitsPerPixel
        self.elevationDeg = elevationDeg
    }

    /// The subject distance, in world units: 1200 at mid, 306 at near's rest, 186 at its limit.
    public var distance: Double {
        Self.distanceConstant / max(scale, 1e-6)
    }

    /// World units of depth per plate row: `unitsPerPixel * cot(e)`.
    public var depthPerRow: Double {
        let e = elevationDeg * .pi / 180
        return unitsPerPixel * cos(e) / max(sin(e), 1e-6)
    }

    /// The depth of a plate row: behind the focal plane (+) or in front of it (-).
    public func delta(row: Double) -> Double {
        (focusRow - row) * depthPerRow
    }

    /// The blur radius, in points, of a thing `delta` world units behind the focal plane
    /// (`.infinity` for the sky): the circle of confusion, capped at `cap` behind and at
    /// `frontCap` in front. A thing at or in front of the camera takes the front cap.
    public func radius(delta: Double) -> Double {
        guard aperture > 0, scale > 0, !delta.isNaN else { return 0 }
        let base = aperture * scale
        if delta == .infinity { return min(base, Self.cap) }
        let limit = delta < 0 ? Self.frontCap : Self.cap
        let d = distance + delta
        guard d > 1e-6 else { return limit }
        return min(base * abs(delta) / d, limit)
    }

    /// The blur radius, in points, of a plate row.
    public func radius(row: Double) -> Double {
        radius(delta: delta(row: row))
    }

    /// The sky's radius (`delta` infinite): `N * s`, capped.
    public var skyRadius: Double {
        radius(delta: .infinity)
    }

    /// A radius a layer applies: zero under `skip`.
    public static func applied(_ r: Double) -> Double {
        r < skip ? 0 : min(r, cap)
    }
}

extension ThinLens {
    /// The shots (v2 §5.2): `plate-home.json` `near.shots`, tuned on stills, not in code. `N`
    /// between them follows the scale: the mid aperture up to `riseFrom`, rising smoothly to the
    /// rest aperture at `riseTo`, holding to the rest scale, then easing to the limit's.
    public struct Shots: Hashable, Sendable, Decodable {
        public struct Shot: Hashable, Sendable, Decodable {
            public var s: Double
            public var N: Double

            public init(s: Double, N: Double) {
                self.s = s
                self.N = N
            }
        }

        public var mid: Shot
        public var station: Shot
        public var rest: Shot
        public var limit: Shot
        public var riseFrom: Double
        public var riseTo: Double
        /// At night the aperture opens: lamps bloom into soft discs.
        public var night: Double

        public init(mid: Shot, station: Shot, rest: Shot, limit: Shot, riseFrom: Double, riseTo: Double, night: Double) {
            self.mid = mid
            self.station = station
            self.rest = rest
            self.limit = limit
            self.riseFrom = riseFrom
            self.riseTo = riseTo
            self.night = night
        }

        /// v2 §5.2's values, for a plate whose data has none.
        public static let standard = Shots(
            mid: Shot(s: 1.145, N: 0.25),
            station: Shot(s: 2.6, N: 0.8),
            rest: Shot(s: 4.5, N: 1.6),
            limit: Shot(s: 7.4, N: 1.3),
            riseFrom: 1.6,
            riseTo: 4,
            night: 1.25
        )

        /// The aperture at scale `s` on the free rail.
        public func aperture(scale s: Double) -> Double {
            func smooth(_ a: Double, _ b: Double, _ x: Double) -> Double {
                let t = min(max((x - a) / max(b - a, 1e-6), 0), 1)
                return t * t * (3 - 2 * t)
            }
            if s <= riseFrom { return mid.N }
            if s <= riseTo { return mid.N + (rest.N - mid.N) * smooth(riseFrom, riseTo, s) }
            if s <= rest.s { return rest.N }
            return rest.N + (limit.N - rest.N) * smooth(rest.s, limit.s, s)
        }

        /// The aperture of a focus on a station or a resident (the build moment, a sheet): the
        /// station shot's while the camera is at or under its scale, the rail's past it.
        public func focusAperture(scale s: Double) -> Double {
            s <= station.s ? station.N : aperture(scale: s)
        }
    }
}
