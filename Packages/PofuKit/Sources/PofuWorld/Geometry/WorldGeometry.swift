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

    public init(sharp: WorldBox?, soft: WorldBox, deep: WorldBox) {
        self.sharp = sharp
        self.soft = soft
        self.deep = deep
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
