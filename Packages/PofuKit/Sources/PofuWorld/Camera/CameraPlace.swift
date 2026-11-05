import Foundation
import PofuCore

/// Where the one camera is in the archipelago: an island and a rail
/// position on it (experience v1 §1.1). `z` runs 0 (Archipelago) to 2
/// (Close) like `CameraRail`, so the rail only gained an island.
public struct CameraPlace: Hashable, Sendable {
    public var island: IslandID
    public var z: Double

    public init(island: IslandID, z: Double) {
        self.island = island
        self.z = z
    }

    /// The designed stop nearest to this place.
    public var stop: PlaceStop {
        PlaceStop(framing: WorldFraming.nearest(to: z))
    }
}

/// The three stops of the one camera, named for the player (§1.1). They
/// map one to one onto `WorldFraming`: Close is Home, Archipelago is the
/// Map.
public enum PlaceStop: Int, CaseIterable, Hashable, Sendable {
    case archipelago = 0
    case island = 1
    case close = 2

    public init(framing: WorldFraming) {
        self = PlaceStop(rawValue: framing.rawValue) ?? .island
    }

    public var framing: WorldFraming {
        WorldFraming(rawValue: rawValue) ?? .island
    }

    /// What the one control shows at this stop: where a tap goes next.
    public var controlGlyph: PlaceGlyph {
        switch self {
        case .close: .island
        case .island: .archipelago
        case .archipelago: .pofu
        }
    }

    /// Where a tap on the one control goes: out one stop, and from the
    /// Archipelago home to Pofu.
    public var controlTarget: PlaceStop {
        switch self {
        case .close: .island
        case .island: .archipelago
        case .archipelago: .close
        }
    }
}

/// The glyph on the one place control (§1.2).
public enum PlaceGlyph: Hashable, Sendable {
    /// An island outline (the next stop is the Island).
    case island
    /// Dots on waves (the next stop is the Archipelago).
    case archipelago
    /// Pofu's face (the next stop is home).
    case pofu
}
