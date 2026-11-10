import Foundation
import PofuCore

/// Something a tap can land on: a box in the world with a depth and a kind
/// (experience v1 §1.3).
public struct HitTarget: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case station(StationID)
        case resident(ResidentID)
        case prop(HomeSlots.Prop)
        case island(IslandID)
        /// A part of today's visit: the visitor, the parcel, the thing that
        /// needs help, the quiet day's letter (§5).
        case visitor(VisitorPart)
        /// Koke itself, on its own island.
        case koke
        /// Çağlayan, on its own island: opens the stage's flow round.
        case caglayan
        /// An object painted into a plate-first home (`HomePlate`), by id.
        case plateObject(String)
    }

    public var kind: Kind
    /// The target's box, absolute in world units.
    public var worldBox: WorldBox
    /// Larger is nearer (`IslandLayout.depth(ofY:)`).
    public var depth: Double
    /// A painted object's outline in world units: the finger must land
    /// inside it (the box is then only its bounds).
    public var polygon: [WorldPoint]?

    public init(kind: Kind, worldBox: WorldBox, depth: Double, polygon: [WorldPoint]? = nil) {
        self.kind = kind
        self.worldBox = worldBox
        self.depth = depth
        self.polygon = polygon
    }
}

/// Whether Koke can be tapped: not yet reachable, reachable (its island
/// answers on the Map) or the camera is on it (Koke answers).
public enum KokeReach: Hashable, Sendable {
    case none
    case arrived
    case onIsland
}

/// The one tap resolver (§1.3), pure and unit-tested: it projects every
/// target, inflates each to at least 44 × 44 pt on screen and returns the
/// frontmost hit; on a tie in depth, the nearest centre.
public enum WorldHitTest {
    /// The smallest a target is on screen, in points.
    public static let minimumTouch = 44.0
    /// Below this rail position only islands answer taps (the Archipelago).
    public static let archipelagoZ = 0.5

    /// A target's rectangle on screen, in points, never smaller than
    /// `minimumTouch` on either side (grown around its centre).
    public static func screenRect(
        of target: HitTarget,
        pose: CameraPose,
        width: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let a = pose.project(WorldPoint(x: target.worldBox.minX, y: target.worldBox.minY), width: width)
        let b = pose.project(WorldPoint(x: target.worldBox.maxX, y: target.worldBox.maxY), width: width)
        let midX = (a.x + b.x) / 2 + offset.x
        let midY = (a.y + b.y) / 2 + offset.y
        let halfW = max(abs(b.x - a.x) / 2, minimumTouch / 2)
        let halfH = max(abs(b.y - a.y) / 2, minimumTouch / 2)
        return (midX - halfW, midY - halfH, midX + halfW, midY + halfH)
    }

    /// The frontmost target under the screen point (`x`, `y`).
    public static func resolve(
        x: Double,
        y: Double,
        targets: [HitTarget],
        pose: CameraPose,
        width: Double,
        offset: (x: Double, y: Double) = (0, 0)
    ) -> HitTarget? {
        var best: (target: HitTarget, distance: Double)?
        let world = pose.unproject(x: x - offset.x, y: y - offset.y, width: width)
        for target in targets {
            let rect = screenRect(of: target, pose: pose, width: width, offset: offset)
            if let polygon = target.polygon {
                let plate = polygon.map { PlatePoint(x: $0.x, y: $0.y) }
                guard PlateMath.contains(plate, PlatePoint(x: world.x, y: world.y)) else { continue }
            } else {
                guard x >= rect.minX, x <= rect.maxX, y >= rect.minY, y <= rect.maxY else { continue }
            }
            let dx = x - (rect.minX + rect.maxX) / 2
            let dy = y - (rect.minY + rect.maxY) / 2
            let distance = dx * dx + dy * dy
            if let current = best {
                if target.depth > current.target.depth + 1e-9
                    || (abs(target.depth - current.target.depth) <= 1e-9 && distance < current.distance) {
                    best = (target, distance)
                }
            } else {
                best = (target, distance)
            }
        }
        return best?.target
    }

    // MARK: - The targets

    /// The islands as targets on the Archipelago: the home plate and every
    /// other island's art.
    public static func islandTargets(koke: Bool = false, caglayan: Bool = false) -> [HitTarget] {
        var targets = [HitTarget(kind: .island(.home), worldBox: IslandFraming.plateBox, depth: 0)]
        if koke {
            targets.append(HitTarget(kind: .island(.koke), worldBox: KokeLayout.islandBox, depth: 0))
        }
        if caglayan {
            targets.append(HitTarget(kind: .island(.caglayan), worldBox: CaglayanLayout.islandBox, depth: 0))
        }
        for isle in IslandLayout.isles {
            if let box = WorldArt.sprite(isle.art)?.sharp {
                targets.append(HitTarget(kind: .island(isle.id), worldBox: IslandFraming.placed(box, at: isle.center), depth: 0))
            }
        }
        return targets
    }

    /// Everything tappable on a plate-first home at rail position `z`
    /// (only the islands on the Archipelago): its painted tap objects (a
    /// station's only once its slot is open), and the residents where they
    /// stand on the plate. The sprite home's objects (the jar, the lantern,
    /// the pots) and the visit are not drawn on the plate.
    public static func plateTargets(
        _ plate: HomePlate,
        stations: [StationStatus],
        z: Double,
        koke: KokeReach = .none,
        caglayan: KokeReach = .none
    ) -> [HitTarget] {
        guard z >= archipelagoZ else { return islandTargets(koke: koke != .none, caglayan: caglayan != .none) }
        var targets: [HitTarget] = []
        for object in plate.objects where object.tap {
            if let station = object.station {
                guard stations.contains(where: { $0.id == station && $0.island == .home && $0.isOpen }) else { continue }
            }
            let polygon = plate.worldPolygon(object)
            let bounds = plate.worldBox(PlateMath.bounds(object.polygon))
            targets.append(HitTarget(kind: .plateObject(object.id), worldBox: bounds, depth: plate.depth(of: object), polygon: polygon))
        }
        for resident in IslandLayout.residents {
            guard let station = stations.first(where: { $0.id == resident.station }), station.level > 0,
                  let feet = plate.residentFeet(resident.id) else { continue }
            let box = plate.residentBox(art: WorldArt.sprite(resident.art)?.sharp ?? IslandLayout.residentHitBox, at: feet)
            targets.append(HitTarget(kind: .resident(resident.id), worldBox: box, depth: IslandLayout.depth(ofY: feet.y) + 0.001))
        }
        return targets
    }

    /// Everything tappable at rail position `z`: only the islands on the
    /// Archipelago, otherwise the home island's open stations, its
    /// residents, the home objects and today's visit.
    public static func targets(
        stations: [StationStatus],
        z: Double,
        visitor: VisitorSnapshot? = nil,
        invitationOpen: Bool = false,
        isBedtime: Bool = false,
        koke: KokeReach = .none,
        caglayan: KokeReach = .none
    ) -> [HitTarget] {
        guard z >= archipelagoZ else { return islandTargets(koke: koke != .none, caglayan: caglayan != .none) }
        var targets: [HitTarget] = []
        if koke == .onIsland {
            targets.append(HitTarget(kind: .koke, worldBox: KokeLayout.kokeBox, depth: IslandLayout.depth(ofY: KokeLayout.center.y)))
        }
        for status in stations where status.island == .home && status.isOpen {
            guard let slot = IslandLayout.stationAnchors[status.id] else { continue }
            let art = IslandLayout.stationArt(status.id, level: max(status.level, 1))?.name
            let footprint = status.level > 0 ? art.map(IslandFootprint.footprint(of:)) ?? IslandFootprint.buildSpot : IslandFootprint.buildSpot
            let anchor = IslandFootprint.clamped(slot, footprint: footprint)
            targets.append(HitTarget(
                kind: .station(status.id),
                worldBox: IslandFraming.placed(IslandLayout.stationHitBox, at: anchor),
                depth: IslandLayout.depth(ofY: anchor.y)
            ))
        }
        for resident in IslandLayout.residents {
            guard let station = stations.first(where: { $0.id == resident.station }), station.level > 0 else { continue }
            let feet = IslandFootprint.clamped(resident.feet, footprint: IslandFootprint.footprint(of: resident.art))
            targets.append(HitTarget(
                kind: .resident(resident.id),
                worldBox: IslandFraming.placed(IslandLayout.residentHitBox, at: feet),
                depth: IslandLayout.depth(ofY: feet.y)
            ))
        }
        for prop in HomeSlots.Prop.allCases {
            targets.append(HitTarget(kind: .prop(prop), worldBox: prop.hitBox, depth: prop.depth))
        }
        targets += VisitorStage.hitTargets(visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime)
        return targets
    }
}
