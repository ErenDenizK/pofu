import Foundation
import PofuCore

/// One row of the lit-source table (light and shadow v2, §4): a thing that
/// throws light at night, and the painted emissive overlay that goes with
/// it. `LightField.make` and the renderer's overlay pass both read this
/// table and nothing else, so a new lit edit (`lighthouse-1-lit`,
/// `path-lamp-lit`, `windmill-1-lit`, `door-mochi-lit`) registers by adding a
/// `<name>-glow` imageset and one row here.
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
        for (id, level, point) in [
            ("window-mochi", 2, WorldPoint(x: 40, y: 84)),
            ("window-findik", 6, WorldPoint(x: 165, y: 80)),
            ("window-goat", 3, WorldPoint(x: 405, y: 50)),
        ] {
            rows.append(LitSourceRow(id: id, kind: .window, requirement: .islandLevel(atLeast: level), point: point, height: 16,
                                     colour: warm, reach: window, shape: .windowSpill, drive: .window(1), overlay: nil))
        }
        rows.append(LitSourceRow(id: "window-guest", kind: .guestRoom, requirement: .guestNight, point: WorldPoint(x: -15, y: 98),
                                 height: 16, colour: GradeRGB(0.95, 0.85, 0.6), reach: window, shape: .windowSpill,
                                 drive: .window(1), overlay: nil))
        // Path lamps (L1-L3) from island level 6.
        for (i, point) in [WorldPoint(x: -120, y: 0), WorldPoint(x: 98, y: 2), WorldPoint(x: 230, y: 6)].enumerated() {
            rows.append(LitSourceRow(id: "lamp-\(i + 1)", kind: .lamp, requirement: .islandLevel(atLeast: 6), point: point, height: 30,
                                     colour: warm, reach: LookTuning.lampReach, shape: .round, drive: .ember(0.8), overlay: nil))
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
