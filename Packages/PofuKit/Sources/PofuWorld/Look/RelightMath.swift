import Foundation

/// Graphics spike: code lighting on painted art through baked normal maps
/// (`tools/assets/normals.py`). This is the pure, testable twin of the
/// `pofuRelight` Metal shader: the same formula in Double, so the numbers
/// can be unit-tested on any platform.
///
/// The painted albedo stays dominant. The light only *modulates* it
/// relative to a flat surface facing the viewer, so a flat region keeps
/// exactly the painted colour and only slopes (bevels, folds, the dome of
/// a body) lighten or darken; practicals add warm light that the albedo
/// tints.
public struct RelightRig: Hashable, Sendable {
    /// A practical light in the lit sprite's local points.
    public struct Point: Hashable, Sendable {
        public var x: Double
        public var y: Double
        /// Height above the sprite plane, in the same units.
        public var height: Double
        public var radius: Double
        /// Colour times strength.
        public var colour: GradeRGB

        public init(x: Double, y: Double, height: Double, radius: Double, colour: GradeRGB) {
            self.x = x
            self.y = y
            self.height = height
            self.radius = radius
            self.colour = colour
        }
    }

    /// A practical in world space (world units).
    public struct WorldPractical: Hashable, Sendable {
        public var point: WorldPoint
        /// Height above the ground plane.
        public var height: Double
        /// Reach.
        public var radius: Double
        /// Colour times strength.
        public var colour: GradeRGB

        public init(point: WorldPoint, height: Double, radius: Double, colour: GradeRGB) {
            self.point = point
            self.height = height
            self.radius = radius
            self.colour = colour
        }
    }

    /// Unit vector toward the key, x right, y up, z toward the viewer.
    public var keyX: Double
    public var keyY: Double
    public var keyZ: Double
    /// Key colour times its intensity.
    public var keyColour: GradeRGB
    /// The fill (sky) colour times its intensity.
    public var ambient: GradeRGB
    /// The rim colour times its intensity.
    public var rim: GradeRGB
    /// The lit practicals; the renderer converts each to a sprite's local
    /// points.
    public var practicals: [WorldPractical]
    /// The tuning lab slider: 0 is off, 1 is the authored strength.
    public var strength: Double

    public init(
        keyX: Double,
        keyY: Double,
        keyZ: Double,
        keyColour: GradeRGB,
        ambient: GradeRGB,
        rim: GradeRGB,
        practicals: [WorldPractical],
        strength: Double
    ) {
        self.keyX = keyX
        self.keyY = keyY
        self.keyZ = keyZ
        self.keyColour = keyColour
        self.ambient = ambient
        self.rim = rim
        self.practicals = practicals
        self.strength = strength
    }

    /// The rig for a moment of the colour script: the cell's key (colour,
    /// intensity, direction), its fill as the ambient, its rim, and every
    /// lit practical.
    public static func make(light: WorldLight, emitters: [WorldEmitter], strength: Double) -> RelightRig {
        let cell = light.cell
        // `from` points toward the light on screen (x right, y down); the
        // shader works y up. A fixed elevation keeps low suns (golden,
        // dawn) raking and high suns (day) frontal enough to read.
        let fx = cell.key.from.x, fy = -cell.key.from.y
        let len = max((fx * fx + fy * fy).squareRoot(), 1e-6)
        let lowSun = min(max((abs(cell.key.from.x) - 0.4) / 0.6, 0), 1)
        let elevation = 0.62 - 0.2 * lowSun
        let planar = (1 - elevation * elevation).squareRoot()
        func scaled(_ c: GradeRGB, _ k: Double) -> GradeRGB { GradeRGB(c.r * k, c.g * k, c.b * k) }
        let lit = emitters.compactMap { e -> WorldPractical? in
            let k = min(e.strength(in: light), 1.2)
            guard k > 0.03 else { return nil }
            return WorldPractical(point: e.point, height: 12, radius: e.reach * 1.5, colour: scaled(e.color, k))
        }
        return RelightRig(
            keyX: fx / len * planar,
            keyY: fy / len * planar,
            keyZ: elevation,
            keyColour: scaled(cell.key.colour, cell.key.intensity),
            ambient: scaled(cell.fill.colour, cell.fill.intensity),
            rim: scaled(cell.rim.colour, cell.rim.intensity * 2.5),
            practicals: lit,
            strength: strength
        )
    }
}

extension RelightRig {
    /// The night's rig (look pipeline v2): the cell's moon key, sky fill and
    /// rim, and every source of the light field (lamps, the tea stall's
    /// ember, Pofu's door, his lantern, the lighthouse when present) as a
    /// practical; nil by day. Its strength follows the night's share of the
    /// hour, so dusk is lit at half strength and day not at all. Pofu is
    /// never self-lit: his light is the nearest source (his lantern).
    public static func night(light: WorldLight, field: LightField) -> RelightRig? {
        let strength = min(max((light.night - LookTuning.nightRelightFrom) / (1 - LookTuning.nightRelightFrom), 0), 1)
        guard strength > 0.01 else { return nil }
        var rig = make(light: light, emitters: [], strength: strength)
        rig.practicals = field.sources.filter { $0.kind != .pond }.map { source in
            let k = min(source.strength, 1.2) * LookTuning.nightRelightSourceGain
            return WorldPractical(
                point: source.point,
                height: source.height,
                radius: source.reach * LookTuning.nightRelightReach,
                colour: GradeRGB(source.colour.r * k, source.colour.g * k, source.colour.b * k)
            )
        }
        return rig
    }

    /// The `count` practicals that reach nearest to `centre` (a sprite's
    /// middle, in the same points `place` maps to), strongest reach first:
    /// the shader lights each sprite from two sources.
    public static func nearest(_ points: [Point], to centre: (x: Double, y: Double), count: Int = 2) -> [Point] {
        let ranked = points.map { p -> (Point, Double) in
            let d = ((p.x - centre.x) * (p.x - centre.x) + (p.y - centre.y) * (p.y - centre.y)).squareRoot()
            return (p, d / max(p.radius, 1e-6))
        }
        return ranked.filter { $0.1 < 1 }.sorted { $0.1 < $1.1 }.prefix(count).map(\.0)
    }
}

public enum RelightMath {
    /// Wrapped diffuse: a soft terminator, never a hard black side.
    static let wrap = 0.35

    @inline(__always)
    static func wrapped(_ x: Double) -> Double {
        min(max((x + wrap) / (1 + wrap), 0), 1)
    }

    public struct Normal: Hashable, Sendable {
        public var x: Double
        public var y: Double
        public var z: Double

        public init(_ x: Double, _ y: Double, _ z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    /// Decodes a normal-map texel (0...1 per channel) to a unit normal.
    public static func normal(r: Double, g: Double, b: Double) -> Normal {
        let x = r * 2 - 1, y = g * 2 - 1, z = b * 2 - 1
        let len = max((x * x + y * y + z * z).squareRoot(), 1e-9)
        return Normal(x / len, y / len, z / len)
    }

    /// The lit colour of a pixel with painted colour `albedo` (0...1) and
    /// tangent-space normal `n`, at local point (`x`, `y`) (y down), under
    /// `rig`. Mirrors `pofuRelight` in `WorldShaders.metal`.
    public static func shade(albedo: GradeRGB, normal n: Normal, x: Double, y: Double, rig: RelightRig) -> GradeRGB {
        let s = rig.strength
        // Key, relative to a flat surface facing the viewer.
        let nl = n.x * rig.keyX + n.y * rig.keyY + n.z * rig.keyZ
        let d = wrapped(nl) - wrapped(rig.keyZ)
        var r = albedo.r * (1 + s * 1.6 * rig.keyColour.r * d)
        var g = albedo.g * (1 + s * 1.6 * rig.keyColour.g * d)
        var b = albedo.b * (1 + s * 1.6 * rig.keyColour.b * d)
        // The sky's fill from above: up-facing slopes brighter, down-facing
        // darker, flat unchanged.
        let sky = s * 0.5 * n.y
        r += albedo.r * rig.ambient.r * sky
        g += albedo.g * rig.ambient.g * sky
        b += albedo.b * rig.ambient.b * sky
        // Practicals: a warm pool that the albedo tints.
        for p in rig.practicals {
            let vx = p.point.x - x, vy = -(p.point.y - y), vz = p.height
            let dist = max((vx * vx + vy * vy + vz * vz).squareRoot(), 1e-6)
            let t = max(1 - dist / max(p.radius, 1e-6), 0)
            let ndl = max((n.x * vx + n.y * vy + n.z * vz) / dist, 0)
            let a = t * t * ndl * s * 1.4
            r += albedo.r * p.colour.r * a
            g += albedo.g * p.colour.g * a
            b += albedo.b * p.colour.b * a
        }
        // A subtle rim on the silhouette side that faces the key.
        let edge = pow(max(1 - n.z, 0), 1.5)
        let side = min(max((n.x * rig.keyX + n.y * rig.keyY) * 1.3 + 0.15, 0), 1)
        let rim = edge * side * s
        r += rig.rim.r * rim
        g += rig.rim.g * rim
        b += rig.rim.b * rim
        func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }
        return GradeRGB(clamp(r), clamp(g), clamp(b))
    }
}
