import Foundation
import PofuCore

/// One thing that throws light into the world at night: an open door
/// window, a path lamp, the ember under the çaydanlık, the calm lantern, the
/// guest room on a visit night, the pond's floating lanterns
/// (`docs/design/experience-v1.md` §2.2).
public struct LightSource: Hashable, Sendable, Identifiable {
    public enum Kind: String, Hashable, Sendable {
        case ember, window, lamp, lantern, guestRoom, pond
    }

    /// The shape of the pool the source throws on the ground.
    public enum PoolShape: String, Hashable, Sendable {
        case round
        case windowSpill
        case pondEllipse
    }

    public var id: String
    public var kind: Kind
    /// Where the light comes from, in world units (a window's sill, a
    /// lamp's foot).
    public var point: WorldPoint
    /// How high the source sits above the ground, in world units; a higher
    /// source lights a character from above.
    public var height: Double
    public var colour: GradeRGB
    /// How far the pool reaches along the ground, in world units.
    public var reach: Double
    public var shape: PoolShape
    /// 0…~1.4: the cell's practical times the source's own state.
    public var strength: Double

    public init(
        id: String,
        kind: Kind,
        point: WorldPoint,
        height: Double,
        colour: GradeRGB,
        reach: Double,
        shape: PoolShape,
        strength: Double
    ) {
        self.id = id
        self.kind = kind
        self.point = point
        self.height = height
        self.colour = colour
        self.reach = reach
        self.shape = shape
        self.strength = strength
    }
}

/// What a character standing at a point receives from the field.
public struct LightSample: Hashable, Sendable {
    /// The dominant source's id, or nil when nothing reaches the point.
    public var sourceID: String?
    public var colour: GradeRGB
    /// The unit vector (world units, x right, y toward the viewer) from the
    /// character toward the dominant source; zero without one.
    public var directionX: Double
    public var directionY: Double
    /// The dominant source's contribution at the point, 0…~1.4.
    public var strength: Double
    /// The dim light every character keeps (the colour script's
    /// `ambientFloor`), so nobody is ever a silhouette.
    public var ambient: Double
    /// The thin cool moon rim, 0…1; it stays on between sources.
    public var moonRim: Double
}

/// The light the island throws at night: its sources, and the questions the
/// renderer asks of them. Pure, so the sampling and the bake's cache key are
/// tested on any platform; `HD2DLayer` draws the pools and the characters'
/// key, bounce and contact shadow from it.
public struct LightField: Hashable, Sendable {
    public var sources: [LightSource]
    /// The colour script's per-cell gains.
    public var ambientFloor: Double
    public var moonRim: Double
    /// The moon rim's colour (the cell's key at night).
    public var moonColour: GradeRGB

    public init(sources: [LightSource], ambientFloor: Double, moonRim: Double, moonColour: GradeRGB) {
        self.sources = sources
        self.ambientFloor = ambientFloor
        self.moonRim = moonRim
        self.moonColour = moonColour
    }

    /// Sources weaker than this are left out of the field (and the bake).
    public static let minimumStrength = 0.02

    /// The strength steps at which the bake is redone: 1/16.
    public static let bakeBuckets = 16

    /// The calm lantern's strength: calm 1…2 maps to 0.4…1.0, so the calmer
    /// the day, the brighter it burns. Monotonic and clamped.
    public static func lanternStrength(calm: Double) -> Double {
        let c = min(max(calm.isFinite ? calm : 1, 1), 2) - 1
        return LookTuning.lanternMinimum + (LookTuning.lanternMaximum - LookTuning.lanternMinimum) * c
    }

    /// The field for a world at a light. Every pool is scaled by the cell's
    /// `poolGain`, so by day they are off.
    ///
    /// - Parameter guestNight: A visitor sleeps in the guest room tonight (H4).
    public static func make(world: WorldSnapshot, light: WorldLight, guestNight: Bool = false) -> LightField {
        let cell = light.cell
        let gain = cell.poolGain
        var sources: [LightSource] = []

        func add(_ source: LightSource) {
            var s = source
            s.strength *= gain
            if s.strength >= minimumStrength { sources.append(s) }
        }

        // Every lit thing of the table (ember, windows, lamps, the pond);
        // a new lit edit registers by adding a row to `LitSources`.
        for row in LitSources.rows where row.isActive(world: world, guestNight: guestNight) {
            add(row.source(strength: row.strength(in: light)))
        }

        // Pofu's calm lantern is his key light at night: it burns whenever
        // the colour script lights practicals, brighter the calmer he is.
        add(LightSource(id: "lantern", kind: .lantern, point: lanternPoint, height: LookTuning.lanternHeight,
                        colour: GradeRGB(1, 0.8, 0.5), reach: LookTuning.lanternReach, shape: .round,
                        strength: lanternStrength(calm: world.calm) * light.bloom))

        return LightField(
            sources: sources.sorted { $0.id < $1.id },
            ambientFloor: cell.ambientFloor,
            moonRim: cell.moonRim,
            moonColour: cell.key.colour
        )
    }

    /// Where the lantern stands: Pofu's feet plus the lantern's slot. Home's
    /// slots (`HomeSlots.lantern`) must match.
    public static var lanternPoint: WorldPoint {
        WorldPoint(x: IslandLayout.pofu.x + LookTuning.lanternOffsetX, y: IslandLayout.pofu.y + LookTuning.lanternOffsetY)
    }

    /// What a character whose feet are at `feet` receives. The dominant
    /// source is the one with the largest contribution (strength times
    /// falloff), which is the nearest of equally strong ones.
    public func sample(_ feet: WorldPoint) -> LightSample {
        var best: (source: LightSource, k: Double, dx: Double, dy: Double)?
        for source in sources {
            let dx = source.point.x - feet.x
            let dy = source.point.y - feet.y
            let d = hypot(dx, dy)
            let t = max(0, 1 - d / max(source.reach, 1))
            let k = source.strength * t * t
            if k > (best?.k ?? 0) { best = (source, k, dx, dy) }
        }
        guard let best, best.k > 1e-4 else {
            return LightSample(sourceID: nil, colour: .zero, directionX: 0, directionY: 0, strength: 0,
                               ambient: ambientFloor, moonRim: moonRim)
        }
        // A raised source lights from above: fold its height into the
        // direction so a lantern at head height is not "level".
        let vx = best.dx
        let vy = best.dy - best.source.height * LookTuning.heightToDepth
        let n = max(hypot(vx, vy), 1e-6)
        return LightSample(
            sourceID: best.source.id,
            colour: best.source.colour,
            directionX: vx / n,
            directionY: vy / n,
            strength: best.k,
            ambient: ambientFloor,
            moonRim: moonRim
        )
    }

    /// What the baked light map depends on: which sources are lit, at which
    /// strength bucket. The bake is redone only when this changes.
    public struct BakeKey: Hashable, Sendable {
        public var entries: [Entry]

        public struct Entry: Hashable, Sendable {
            public var id: String
            public var bucket: Int
        }
    }

    public var bakeKey: BakeKey {
        BakeKey(entries: sources.compactMap { source in
            let bucket = Int((min(source.strength, 1.5) * Double(Self.bakeBuckets)).rounded())
            return bucket > 0 ? BakeKey.Entry(id: source.id, bucket: bucket) : nil
        }.sorted { $0.id < $1.id })
    }

    /// The world rectangle the light map covers (Home to the harbor).
    public static let mapBounds = WorldBox(minX: -260, minY: -200, maxX: 540, maxY: 200)

    /// The light map's size in pixels.
    public static let mapWidth = 512
    public static let mapHeight = 256

    /// Nothing is lit: no pools to bake or draw.
    public var isDark: Bool { sources.isEmpty }
}
