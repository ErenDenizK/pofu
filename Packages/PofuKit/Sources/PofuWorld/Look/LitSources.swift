import Foundation
import PofuCore

/// One row of the lit-source table (light and shadow v2, §4): a thing that
/// throws light at night, and the painted emissive overlay that goes with
/// it. `LightField.make` and the renderer's overlay pass both read this
/// table and nothing else, so a new lit edit (`windmill-1-lit`, ...)
/// registers by adding a `<name>-glow` imageset and one row here. The
/// lighthouse's lamp room, the path lamps' glass and Mochi's door window
/// are rows already.
public struct LitSourceRow: Hashable, Sendable {
    /// When the source exists.
    public enum Requirement: Hashable, Sendable {
        case always
        /// From this island level on.
        case islandLevel(atLeast: Int)
        /// While the station's level is in `from...through`.
        case station(StationID, from: Int, through: Int)
        /// A visitor sleeps in the guest room tonight.
        case guestNight
    }

    /// Which of the colour script's practicals drives the source, times a
    /// factor.
    public enum Drive: Hashable, Sendable {
        case ember(Double)
        case window(Double)
    }

    /// The painted overlay (`<art>` in the world catalog, the difference of
    /// a lit edit against its day master).
    public struct Overlay: Hashable, Sendable {
        public var art: String
        /// The station level the overlay was painted for; nil for a
        /// free-standing overlay (a path lamp).
        public var level: Int?
    }

    public var id: String
    public var kind: LightSource.Kind
    public var requirement: Requirement
    /// Where the light comes from, in world units.
    public var point: WorldPoint
    public var height: Double
    public var colour: GradeRGB
    /// The pool's reach along the ground, in world units (the "radius").
    public var reach: Double
    public var shape: LightSource.PoolShape
    public var drive: Drive
    public var overlay: Overlay?
    /// The island the source stands on. Another island's source has its painted overlay (the harbor's
    /// lighthouse) but throws no light on the home lawn, so `LightField` leaves it out.
    public var island: IslandID = .home

    /// Whether the source exists for `world`.
    public func isActive(world: WorldSnapshot, guestNight: Bool) -> Bool {
        switch requirement {
        case .always: true
        case .islandLevel(let minimum): world.islandLevel >= minimum
        case .guestNight: guestNight
        case .station(let station, let from, let through):
            if let level = world.stations.first(where: { $0.id == station })?.level { (from...through).contains(level) } else { false }
        }
    }

    /// Where this row's painted overlay is drawn for `world`, if it has one
    /// and the row is active: a station's overlay sits on the station's
    /// (footprint-clamped) anchor and only at the level it was painted for;
    /// a free-standing one sits on the source's point.
    public func overlayAnchor(world: WorldSnapshot, guestNight: Bool) -> (art: String, anchor: WorldPoint)? {
        guard let overlay, isActive(world: world, guestNight: guestNight) else { return nil }
        if island != .home {
            // Another island's station: its overlay stands where the station's art does, in the world
            // canvas, while the station shows the art the overlay was painted on.
            guard case .station(let station, _, _) = requirement,
                  let isle = IslandLayout.isles.first(where: { $0.id == island }),
                  let slot = IslandLayout.harborStationSlots[station],
                  let level = world.stations.first(where: { $0.id == station })?.level,
                  IslandLayout.stationArt(station, level: level)?.name == overlay.art.replacingOccurrences(of: "-glow", with: "") else { return nil }
            return (overlay.art, WorldPoint(x: isle.center.x + slot.x, y: isle.center.y + slot.y))
        }
        guard case .station(let station, _, _) = requirement else { return (overlay.art, point) }
        guard let level = world.stations.first(where: { $0.id == station })?.level,
              overlay.level == nil || overlay.level == level,
              let slot = IslandLayout.stationAnchors[station],
              let art = IslandLayout.stationArt(station, level: level)?.name else { return nil }
        return (overlay.art, IslandFootprint.clamped(slot, footprint: IslandFootprint.footprint(of: art)))
    }

    /// The strength under `light`, 0…~1.4, before the cell's pool gain.
    public func strength(in light: WorldLight) -> Double {
        switch drive {
        case .ember(let factor): light.practicals.ember * light.bloom * factor
        case .window(let factor): light.practicals.window * light.bloom * factor
        }
    }

    /// The light the table row throws.
    public func source(strength: Double) -> LightSource {
        LightSource(id: id, kind: kind, point: point, height: height, colour: colour, reach: reach, shape: shape, strength: strength)
    }
}

/// The table.
public enum LitSources {
    private static let warm = GradeRGB(1, 0.78, 0.44)

    private static func station(_ id: StationID, _ x: Double, _ y: Double) -> WorldPoint {
        IslandLayout.onStation(id, x: x, y: y)
    }

    /// A harbor station's slot on the world canvas.
    private static func harbor(_ station: StationID) -> WorldPoint {
        let isle = IslandLayout.isles.first { $0.id == .harbor }?.center ?? .zero
        let slot = IslandLayout.harborStationSlots[station] ?? .zero
        return WorldPoint(x: isle.x + slot.x, y: isle.y + slot.y)
    }

    private static func emitter(_ kind: WorldEmitter.Kind) -> WorldEmitter {
        IslandLayout.emitters.first { $0.kind == kind } ?? IslandLayout.emitters[0]
    }

    public static let rows: [LitSourceRow] = {
        let ember = emitter(.ember)
        let door = emitter(.window)
        let window = LookTuning.windowSpillReach
        var rows: [LitSourceRow] = [
            // The flame under the çaydanlık, on every level of the stall;
            // the painted flame is the level 1 lit edit.
            LitSourceRow(id: "ember", kind: .ember, requirement: .station(.teaStall, from: 1, through: Int.max),
                         point: ember.point, height: 14, colour: ember.color, reach: ember.reach, shape: .round,
                         drive: .ember(1), overlay: .init(art: "tea-stall-1-glow", level: 1)),
            // The harbor lighthouse's lamp room (masked lit edit, `lighthouse-1-lit`): its glow is painted over
            // the harbor's own art; the lamp room is 37.7 units up the tower at the harbor's 0.7 scale.
            LitSourceRow(id: "lamp-lighthouse", kind: .lamp, requirement: .station(.lighthouse, from: 1, through: Int.max),
                         point: harbor(.lighthouse), height: 37.7, colour: warm, reach: LookTuning.lampReach * 2, shape: .round,
                         drive: .ember(1), overlay: .init(art: "lighthouse-1-glow", level: nil), island: .harbor),
            // The round window in Pofu's door (on the plate).
            LitSourceRow(id: "window-pofu", kind: .window, requirement: .always, point: door.point, height: 16,
                         colour: door.color, reach: window, shape: .windowSpill, drive: .window(1), overlay: nil),
            // The workshop's lit window and the windmill's lit band
            // (measured on the glow sprites' boxes).
            LitSourceRow(id: "window-workshop", kind: .window, requirement: .station(.workshop, from: 1, through: 1),
                         point: station(.workshop, -32.6, -8), height: 14, colour: warm, reach: window, shape: .windowSpill,
                         drive: .window(1), overlay: .init(art: "workshop-1-glow", level: 1)),
            LitSourceRow(id: "window-windmill", kind: .window, requirement: .station(.windmill, from: 5, through: 5),
                         point: station(.windmill, -3.8, -18.4), height: 14, colour: warm, reach: window, shape: .windowSpill,
                         drive: .window(1), overlay: .init(art: "windmill-5-glow", level: 5)),
            // The pond's floating lanterns (pond level 5): a cool shimmer.
            LitSourceRow(id: "pond", kind: .pond, requirement: .station(.pond, from: 5, through: Int.max),
                         point: station(.pond, 0, 0), height: 2, colour: GradeRGB(0.55, 0.9, 0.85), reach: LookTuning.pondReach,
                         shape: .pondEllipse, drive: .ember(0.6), overlay: .init(art: "pond-5-glow", level: 5)),
        ]
        // The residents' doors open with the island (home-layout §3.2).
        for (id, level, point, art) in ([
            ("window-mochi", 2, WorldPoint(x: 40, y: 84), "door-mochi-glow"),
            ("window-findik", 6, WorldPoint(x: 165, y: 80), nil),
            ("window-goat", 3, WorldPoint(x: 405, y: 50), nil),
        ] as [(String, Int, WorldPoint, String?)]) {
            // Mochi's door: the masked lit edit of the door (`door-mochi-lit`), centred like the door.
            rows.append(LitSourceRow(id: id, kind: .window, requirement: .islandLevel(atLeast: level), point: point, height: 16,
                                     colour: warm, reach: window, shape: .windowSpill, drive: .window(1),
                                     overlay: art.map { .init(art: $0, level: nil) }))
        }
        rows.append(LitSourceRow(id: "window-guest", kind: .guestRoom, requirement: .guestNight, point: WorldPoint(x: -15, y: 98),
                                 height: 16, colour: GradeRGB(0.95, 0.85, 0.6), reach: window, shape: .windowSpill,
                                 drive: .window(1), overlay: nil))
        // Path lamps (L1-L3) from island level 6: the painted lamp stands on the point, its paper glass
        // 14.5 units up (`path-lamp-glow`, the masked lit edit).
        for (i, point) in HomeFixtures.lampFeet.enumerated() {
            rows.append(LitSourceRow(id: "lamp-\(i + 1)", kind: .lamp, requirement: .islandLevel(atLeast: HomeFixtures.lampsOpenAtLevel), point: point, height: 14.5,
                                     colour: warm, reach: LookTuning.lampReach, shape: .round, drive: .ember(0.8),
                                     overlay: .init(art: "path-lamp-glow", level: nil)))
        }
        return rows
    }()

    /// The row whose overlay is painted for a station level, if any.
    public static func overlay(_ station: StationID, level: Int) -> LitSourceRow.Overlay? {
        for row in rows {
            if case .station(let s, _, _) = row.requirement, s == station,
               let overlay = row.overlay, overlay.level == level, WorldArt.sprite(overlay.art) != nil {
                return overlay
            }
        }
        return nil
    }
}
