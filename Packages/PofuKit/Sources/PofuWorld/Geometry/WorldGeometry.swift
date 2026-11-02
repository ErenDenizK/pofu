import Foundation

/// A point in world units: points at camera scale 1, with the home
/// island's lawn centre at the origin and y growing toward the viewer
/// (game design §15; interaction spec §1.2).
public struct WorldPoint: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = WorldPoint(x: 0, y: 0)
}

/// A rectangle in world units, relative to an object's anchor (its feet
/// or its footprint centre).
public struct WorldBox: Hashable, Sendable {
    public var minX: Double
    public var minY: Double
    public var maxX: Double
    public var maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    public var width: Double {
        maxX - minX
    }

    public var height: Double {
        maxY - minY
    }

    public var midX: Double {
        (minX + maxX) / 2
    }

    public var midY: Double {
        (minY + maxY) / 2
    }

    public func contains(_ point: WorldPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}

/// One world image and its two pre-blurred variants (interaction spec
/// §5.3): each has its own box, because a blurred image is padded by 3σ on
/// every side and stored at a lower resolution.
public struct WorldSprite: Hashable, Sendable {
    /// `nil` when something else draws the sharp image (Pofu's live
    /// companion view).
    public var sharp: WorldBox?
    public var soft: WorldBox
    public var deep: WorldBox
    /// Where the object meets the ground, measured from its alpha by the
    /// pipeline: a convex polygon relative to the anchor (look round 2,
    /// containment). Empty for images that do not stand on the lawn.
    public var footprint: [WorldPoint]

    public init(sharp: WorldBox?, soft: WorldBox, deep: WorldBox, footprint: [WorldPoint] = []) {
        self.sharp = sharp
        self.soft = soft
        self.deep = deep
        self.footprint = footprint
    }
}

/// A closed polygon in world units.
public struct WorldPolygon: Hashable, Sendable {
    public var points: [WorldPoint]

    public init(_ points: [WorldPoint]) {
        self.points = points
    }

    /// Whether `point` is inside (even-odd rule; a point on an edge may
    /// land either way).
    public func contains(_ point: WorldPoint) -> Bool {
        guard points.count >= 3 else { return false }
        var inside = false
        var j = points.count - 1
        for i in points.indices {
            let a = points[i], b = points[j]
            if (a.y > point.y) != (b.y > point.y) {
                let x = a.x + (point.y - a.y) * (b.x - a.x) / (b.y - a.y)
                if point.x < x {
                    inside.toggle()
                }
            }
            j = i
        }
        return inside
    }

    /// The polygon moved by `point`.
    public func offset(by point: WorldPoint) -> WorldPolygon {
        WorldPolygon(points.map { WorldPoint(x: $0.x + point.x, y: $0.y + point.y) })
    }

    /// The axis-aligned bounds, or `nil` when empty.
    public var bounds: WorldBox? {
        guard let first = points.first else { return nil }
        return points.dropFirst().reduce(WorldBox(minX: first.x, minY: first.y, maxX: first.x, maxY: first.y)) { box, p in
            WorldBox(minX: min(box.minX, p.x), minY: min(box.minY, p.y), maxX: max(box.maxX, p.x), maxY: max(box.maxY, p.y))
        }
    }

    /// An ellipse as a polygon of `segments` points.
    public static func ellipse(radiusX: Double, radiusY: Double, segments: Int = 16) -> WorldPolygon {
        WorldPolygon((0..<max(segments, 3)).map { i in
            let t = Double(i) / Double(max(segments, 3)) * 2 * Double.pi
            return WorldPoint(x: radiusX * cos(t), y: radiusY * sin(t))
        })
    }
}

/// The world art the pipeline baked into `World.xcassets`
/// (`design/prototypes/interactions/tools/preblur.py app`). An image set
/// is named `world-<name>`, with `__soft` and `__deep` variants.
public enum WorldArt {
    /// The sprite named `name`, or `nil` when the pipeline did not bake it.
    public static func sprite(_ name: String) -> WorldSprite? {
        generated[name]
    }

    /// Every baked sprite's name.
    public static var names: [String] {
        generated.keys.sorted()
    }

    /// A plate's walkable polygon, measured from its lawn by the pipeline,
    /// relative to the plate's anchor; `nil` when the plate has none.
    public static func walkable(_ plate: String) -> WorldPolygon? {
        generatedWalkable[plate].map(WorldPolygon.init)
    }

    /// The image set holding `name` at `variant`.
    public static func assetName(_ name: String, variant: DepthVariant) -> String {
        switch variant {
        case .sharp: "world-\(name)"
        case .soft: "world-\(name)__soft"
        case .deep: "world-\(name)__deep"
        }
    }
}

/// The three baked blur levels.
public enum DepthVariant: Hashable, Sendable, CaseIterable {
    case sharp
    case soft
    case deep
}

extension WorldSprite {
    public func box(for variant: DepthVariant) -> WorldBox? {
        switch variant {
        case .sharp: sharp
        case .soft: soft
        case .deep: deep
        }
    }
}
