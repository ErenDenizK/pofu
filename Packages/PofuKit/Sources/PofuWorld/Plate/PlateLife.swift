import Foundation
import PofuCore

/// The plate's living layer (game solid v1, PR 6): where the daily visit,
/// Koke's moss, Çağlayan's fountain and a build moment's dust and light go on
/// the painted home plate. Pure and Linux-tested.
///
/// The plate is final art, so nothing here is hand-placed in
/// `plate-home.json` (the art track's file): every spot is computed from the
/// plate's `walkable` lawn, its characters and its station polygons.
///
/// Positions are plate pixels while they are searched (so the clearances read
/// as the painting does) and world units once returned (`HomePlate.world`).
public enum PlateLife {
    /// The lawn is sampled every this many plate pixels.
    public static let gridStep = 10.0
    /// How far from the visitor the parcel lies, in world units: the sprite island's
    /// 20 pulled in so it clears Fındık, who stands on the visitor's other side.
    public static let giftReach = 16.0
    /// How far (plate pixels) the moss lies from every character and from the
    /// visitor.
    public static let mossClearance = 30.0

    // MARK: - The visitor

    /// Where the visitor stands: the lawn point farthest from Pofu, Mochi and
    /// Findik (the grid point whose smallest distance to a character is the
    /// largest; ties go to the smaller x, then y).
    public static func visitorSpot(_ plate: HomePlate) -> WorldPoint {
        let characters = plate.plate.characters.values.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var best: (clearance: Double, point: PlatePoint)?
        for point in lawn(plate) {
            let clearance = characters.map { distance($0, point) }.min() ?? .infinity
            // Strictly larger only: the grid runs by x then y, so a tie keeps
            // the earlier (smaller) point.
            if best == nil || clearance > best!.clearance + 1e-9 {
                best = (clearance, point)
            }
        }
        if let best {
            return plate.world(best.point)
        }
        // No lawn in the plate's data: the island's middle, so a visit still has a spot.
        let box = plate.plate.islandBox
        return plate.world(PlatePoint(x: (box.minX + box.maxX) / 2, y: (box.minY + box.maxY) / 2))
    }

    /// The parts of today's visit (`VisitorStage.parts`), moved from the
    /// sprite island's slot to the plate's visitor spot. The help target keeps
    /// its offset from the visitor; the parcel lies `giftReach` away on
    /// the side away from Pofu (on the sprite island it lies to the left, which
    /// here is under Pofu).
    public static func visitorParts(
        plate: HomePlate,
        visitor: VisitorSnapshot?,
        invitationOpen: Bool,
        isBedtime: Bool
    ) -> [VisitorStage.Placed] {
        // A quiet day's letter has no visitor: it lies at the sprite island's
        // letter spot, which moves to the visitor spot the same way.
        let from = visitor.map(VisitorStage.feet(of:)) ?? VisitorStage.letterSpot
        let to = visitorSpot(plate)
        let dx = to.x - from.x, dy = to.y - from.y
        let pofu = plate.plate.characters["pofu"]
        let spot = plate.plate(to)
        // Right of the visitor unless Pofu stands to the right of them.
        let giftSide = pofu.map { $0.x > spot.x ? -1.0 : 1.0 } ?? 1.0
        return VisitorStage.parts(visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime).map {
            if $0.part == .gift {
                let reach = giftReach
                return VisitorStage.Placed(part: .gift, feet: WorldPoint(x: to.x + giftSide * reach, y: $0.feet.y + dy))
            }
            return VisitorStage.Placed(part: $0.part, feet: WorldPoint(x: $0.feet.x + dx, y: $0.feet.y + dy))
        }
    }

    /// The visit's parts as tap targets (`VisitorStage.hitTargets`), their boxes
    /// moved the same way.
    public static func visitorTargets(
        plate: HomePlate,
        visitor: VisitorSnapshot?,
        invitationOpen: Bool,
        isBedtime: Bool
    ) -> [HitTarget] {
        visitorParts(plate: plate, visitor: visitor, invitationOpen: invitationOpen, isBedtime: isBedtime).map {
            HitTarget(kind: .visitor($0.part), worldBox: $0.hitBox, depth: $0.depth)
        }
    }

    // MARK: - The gifts

    /// Where Koke's moss lies: the lawn point nearest the sprite island's gift
    /// spot (`KokeLayout.homeGift`) that is at least `mossClearance` plate
    /// pixels from every character and from the visitor.
    public static func mossSpot(_ plate: HomePlate) -> WorldPoint? {
        let wanted = plate.plate(KokeLayout.homeGift)
        let visitor = plate.plate(visitorSpot(plate))
        let others = plate.plate.characters.values.sorted { ($0.x, $0.y) < ($1.x, $1.y) } + [visitor]
        var best: (distance: Double, point: PlatePoint)?
        for point in lawn(plate) where others.allSatisfy({ distance($0, point) >= mossClearance }) {
            let d = distance(wanted, point)
            if best == nil || d < best!.distance - 1e-9 {
                best = (d, point)
            }
        }
        return best.map { plate.world($0.point) }
    }

    /// Where Çağlayan's fountain stands: the top centre of the pond, or `nil`
    /// when the plate has no pond.
    public static func fountainSpot(_ plate: HomePlate) -> WorldPoint? {
        buildAnchor(plate, station: .pond)
    }

    // MARK: - The build moment

    /// The top centre of a station's painted object: where "Seviye N!" stands.
    public static func buildAnchor(_ plate: HomePlate, station: StationID) -> WorldPoint? {
        plate.stationBox(station).map { WorldPoint(x: $0.midX, y: $0.minY) }
    }

    /// The bottom centre of a station's painted object: the footprint the
    /// dust and the burst of light are measured from (as on the sprite
    /// island, where `BuildMoment` places them around the station's anchor).
    public static func buildFoot(_ plate: HomePlate, station: StationID) -> WorldPoint? {
        plate.stationBox(station).map { WorldPoint(x: $0.midX, y: $0.maxY) }
    }

    // MARK: - The lawn

    /// The walkable lawn on a `gridStep` grid, by x then y.
    static func lawn(_ plate: HomePlate) -> [PlatePoint] {
        let polygon = plate.plate.walkable
        guard polygon.count >= 3 else { return [] }
        let bounds = PlateMath.bounds(polygon)
        var points: [PlatePoint] = []
        var x = (bounds.minX / gridStep).rounded(.up) * gridStep
        while x <= bounds.maxX {
            var y = (bounds.minY / gridStep).rounded(.up) * gridStep
            while y <= bounds.maxY {
                let point = PlatePoint(x: x, y: y)
                if PlateMath.contains(polygon, point) {
                    points.append(point)
                }
                y += gridStep
            }
            x += gridStep
        }
        return points
    }

    private static func distance(_ a: PlatePoint, _ b: PlatePoint) -> Double {
        hypot(a.x - b.x, a.y - b.y)
    }
}
