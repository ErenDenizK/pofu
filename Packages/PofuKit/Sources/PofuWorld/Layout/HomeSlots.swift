import Foundation

/// Where the jar, the calm lantern and the skip pots stand in the world
/// (experience v1 §1.4). They were screen offsets from Pofu's feet at Home
/// (`HomeObjectsLayout`); the points below are those offsets divided by
/// `IslandFraming.homeScale`, so Home looks the same, and now they share
/// the island's transform: they never lag or bob, and the tap resolver
/// finds them in every framing.
///
/// Each slot is the object's centre, as the screen layout had it.
public enum HomeSlots {
    private static var scale: Double { IslandFraming.homeScale }

    /// The jar's centre: left of Pofu, its base on the lawn.
    public static var jar: WorldPoint {
        WorldPoint(x: IslandLayout.pofu.x - 100 / scale, y: IslandLayout.pofu.y - 30 / scale)
    }

    /// The lantern's centre: right of Pofu.
    public static var lantern: WorldPoint {
        WorldPoint(
            x: IslandLayout.pofu.x + 102 / scale,
            y: IslandLayout.pofu.y + (-HomeObjectsLayout.lanternHeight / 2 + 2) / scale
        )
    }

    /// The centre of the pot row on the island's lip.
    public static var pots: WorldPoint {
        WorldPoint(x: IslandLayout.pofu.x, y: IslandLayout.pofu.y + 112 / scale)
    }

    /// The lantern's offset from Pofu's feet: the light field's emitter
    /// sits at `IslandLayout.pofu` plus this (experience v1 §7).
    public static var lanternEmitterOffset: WorldPoint {
        WorldPoint(x: lantern.x - IslandLayout.pofu.x, y: lantern.y - IslandLayout.pofu.y)
    }

    /// The home objects, in tap order.
    public enum Prop: String, CaseIterable, Hashable, Sendable {
        case jar
        case lantern
        case pots

        /// The prop's centre in the world.
        public var slot: WorldPoint {
            switch self {
            case .jar: HomeSlots.jar
            case .lantern: HomeSlots.lantern
            case .pots: HomeSlots.pots
            }
        }

        /// The prop's art size on screen at Home, in points.
        public var homeSize: (width: Double, height: Double) {
            switch self {
            case .jar: (HomeObjectsLayout.jarSize.width, HomeObjectsLayout.jarSize.height)
            case .lantern: (44, HomeObjectsLayout.lanternHeight)
            case .pots: (HomeObjectsLayout.potWidth * 4, HomeObjectsLayout.potWidth * 1.3)
            }
        }

        /// The prop's tap box in world units, around its slot.
        public var hitBox: WorldBox {
            let size = homeSize
            let w = size.width / HomeSlots.scale, h = size.height / HomeSlots.scale
            return WorldBox(minX: slot.x - w / 2, minY: slot.y - h / 2, maxX: slot.x + w / 2, maxY: slot.y + h / 2)
        }

        /// The prop's depth: its base row, like any standing object.
        public var depth: Double {
            IslandLayout.depth(ofY: slot.y + homeSize.height / 2 / HomeSlots.scale)
        }
    }
}
