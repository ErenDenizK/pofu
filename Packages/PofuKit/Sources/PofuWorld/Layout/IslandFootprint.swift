import Foundation
import PofuCore

/// Containment (look round 2): everything that stands on the home island
/// stands inside its walkable footprint, so no station, resident or Pofu
/// hangs over the plate's rim.
///
/// Both sides are measured, not authored: the pipeline
/// (`preblur.py app`) erodes the plate's lawn by a few units into the
/// walkable polygon and takes each sprite's footprint from its alpha (the
/// convex hull of its bottom rows, the ground ellipse of the station
/// guide). The layout's anchors are authored; `IslandFootprintTests` fails
/// when any placement leaves the polygon, and the scene draws through
/// `clamped(_:footprint:)` so a new, wider art can never stick out.
public enum IslandFootprint {
    /// The home plate's art name.
    public static let plate = "island-main"

    /// The home plate's walkable polygon in world units.
    public static var walkable: WorldPolygon? {
        WorldArt.walkable(plate)
    }

    /// An open, unbuilt slot's dashed ellipse (64 × 18 pt).
    public static let buildSpot = WorldPolygon.ellipse(radiusX: 32, radiusY: 9)

    /// One thing standing on the lawn: an anchor and its footprint.
    public struct Placement: Hashable, Sendable {
        public var id: String
        public var anchor: WorldPoint
        public var footprint: WorldPolygon
    }

    /// The footprint of a baked sprite, empty when it has none.
    public static func footprint(of art: String) -> WorldPolygon {
        WorldPolygon(WorldArt.sprite(art)?.footprint ?? [])
    }

    /// Everything the home island can show: every slot's build spot and
    /// every level's art, every resident and Pofu.
    public static var placements: [Placement] {
        var result: [Placement] = []
        for (station, anchor) in IslandLayout.stationAnchors.sorted(by: { $0.key < $1.key }) {
            result.append(Placement(id: "\(station) spot", anchor: anchor, footprint: buildSpot))
            var seen = Set<String>()
            for level in 1...5 {
                guard let art = IslandLayout.stationArt(station, level: level)?.name, seen.insert(art).inserted else { continue }
                result.append(Placement(id: "\(station) \(art)", anchor: anchor, footprint: footprint(of: art)))
            }
        }
        for resident in IslandLayout.residents {
            result.append(Placement(id: "\(resident.id) \(resident.art)", anchor: resident.feet, footprint: footprint(of: resident.art)))
        }
        result.append(Placement(id: "pofu", anchor: IslandLayout.pofu, footprint: footprint(of: "pofu")))
        return result
    }

    /// Whether `footprint` placed at `anchor` lies inside the walkable
    /// polygon (every vertex and the anchor itself). Without a polygon,
    /// everything fits.
    public static func fits(_ footprint: WorldPolygon, at anchor: WorldPoint) -> Bool {
        guard let walkable else { return true }
        guard walkable.contains(anchor) else { return false }
        return footprint.points.allSatisfy { walkable.contains(WorldPoint(x: $0.x + anchor.x, y: $0.y + anchor.y)) }
    }

    /// The placements that do not fit, by id.
    public static var offenders: [String] {
        placements.filter { !fits($0.footprint, at: $0.anchor) }.map(\.id)
    }

    /// `anchor` itself when the footprint fits there; otherwise the first
    /// point on the way to the lawn's centre where it does (half-unit
    /// steps), or the centre when nothing fits.
    public static func clamped(_ anchor: WorldPoint, footprint: WorldPolygon) -> WorldPoint {
        guard let walkable, let bounds = walkable.bounds, !fits(footprint, at: anchor) else { return anchor }
        let centre = WorldPoint(x: bounds.midX, y: bounds.midY)
        let dx = centre.x - anchor.x, dy = centre.y - anchor.y
        let steps = max(Int((hypot(dx, dy) * 2).rounded(.up)), 1)
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let p = WorldPoint(x: anchor.x + dx * t, y: anchor.y + dy * t)
            if fits(footprint, at: p) {
                return p
            }
        }
        return centre
    }
}
