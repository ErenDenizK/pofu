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
    }

    public var kind: Kind
    /// The target's box, absolute in world units.
    public var worldBox: WorldBox
    /// Larger is nearer (`IslandLayout.depth(ofY:)`).
    public var depth: Double

    public init(kind: Kind, worldBox: WorldBox, depth: Double) {
        self.kind = kind
        self.worldBox = worldBox
        self.depth = depth
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
        for target in targets {
            let rect = screenRect(of: target, pose: pose, width: width, offset: offset)
            guard x >= rect.minX, x <= rect.maxX, y >= rect.minY, y <= rect.maxY else { continue }
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
