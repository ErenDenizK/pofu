import Foundation
import PofuCore

/// The home island's fixed painted things that are not stations, residents
/// or lawn dressing: the residents' round doors in the plate's earth face
/// (home layout H2, H3) and the bees' hive on the middle lawn (S6). Pure
/// data and rules, so they are tested on any platform; the scene draws each
/// as one baked sprite (`FixtureView`).
public enum HomeFixtures {
    /// One door in the earth face: it is there from an island level, and its
    /// slot is the centre of the frame (the plate's own door, Pofu's H1, is
    /// painted into the plate).
    public struct Door: Hashable, Sendable, Identifiable {
        public var id: String
        public var art: String
        public var centre: WorldPoint
        public var opensAtLevel: Int
    }

    /// Mochi's rose door with the tea-glass sign, from the island level her
    /// station opens (H2), and Fındık's sage door with the gear sign when
    /// the workshop opens (H3). Painted into the earth-face plates; `art` is
    /// the retired sprite's name.
    public static let doors: [Door] = [
        Door(id: "door-mochi", art: "door-mochi", centre: WorldPoint(x: 40, y: 84), opensAtLevel: 2),
        Door(id: "door-findik", art: "door-findik", centre: WorldPoint(x: 165, y: 80), opensAtLevel: 6),
    ]

    /// The doors shown at an island level.
    public static func doors(atLevel level: Int) -> [Door] {
        doors.filter { level >= $0.opensAtLevel }
    }

    /// The path lamps (home layout L1 to L3): the one painted `path-lamp` stands on each of these feet from
    /// the island level the lamps open at. `LitSources` lights their paper glass at night.
    public static let lampFeet: [WorldPoint] = [WorldPoint(x: -120, y: 0), WorldPoint(x: 98, y: 2), WorldPoint(x: 230, y: 6)]
    /// The island level the lamps open at.
    public static let lampsOpenAtLevel = 6

    /// The hive's slot (S6): the footprint centre, on the back lawn between
    /// the workshop and the tea stall. The layout planned it in front of
    /// the windmill's right foot, (-32, -6), but the workshop's painted
    /// ground reaches to x -55 there, so no spot between the pond and the
    /// workshop is free; this is the one gap on the lawn that holds the hive
    /// at its widest (hive 3) clear of every station, resident and Pofu.
    public static let hiveSlot = WorldPoint(x: 74, y: -6)
    /// The island level the hive's slot opens at (with Arı).
    public static let hiveOpensAtLevel = 9
    /// The hive ladder's baked levels (`hive-1` to `hive-3`).
    public static let hiveLevels = 3

    /// The hive's painted level. The hive is a gift station whose own levels
    /// are not in the game yet, so the island carries it: the straw skep
    /// when the slot opens (IL9), a second skep and the lavender at the top
    /// island level (IL10), and the painted hive box beside them once every
    /// home station is at its top level (full bloom). 0 is no hive.
    public static func hiveLevel(islandLevel: Int, homeStationsAtTop: Bool) -> Int {
        guard islandLevel >= hiveOpensAtLevel else { return 0 }
        guard islandLevel > hiveOpensAtLevel else { return 1 }
        return homeStationsAtTop ? 3 : 2
    }

    /// The hive's baked sprite at a level; `nil` when there is no hive.
    public static func hiveArt(level: Int) -> String? {
        level > 0 ? "hive-\(min(level, hiveLevels))" : nil
    }

    /// One fixture to draw: its sprite and where it stands (the frame's
    /// centre for a door, the footprint centre for the hive).
    public struct Placed: Hashable, Sendable, Identifiable {
        public var id: String
        public var art: String
        public var point: WorldPoint
    }

    /// The earth-face plate for an island level (batch 60): the residents' doors are painted into the
    /// earth, Mochi's from level 2 and Fındık's from level 6, so the pasted door sprites are retired.
    /// The outline is the main plate's at every level.
    public static func plateStem(islandLevel: Int) -> String {
        if islandLevel >= 6 { return "island-main-face-il6" }
        if islandLevel >= 2 { return "island-main-face-il2" }
        return "island-main"
    }

    /// Every fixture shown at an island level: the path lamps and the hive. The doors are part of the
    /// plate (`plateStem`), their slots stay here for the lit windows.
    public static func placed(islandLevel: Int, homeStationsAtTop: Bool) -> [Placed] {
        var result: [Placed] = []
        if islandLevel >= lampsOpenAtLevel {
            for (i, feet) in lampFeet.enumerated() {
                result.append(Placed(id: "lamp-\(i + 1)", art: "path-lamp", point: feet))
            }
        }
        if let art = hiveArt(level: hiveLevel(islandLevel: islandLevel, homeStationsAtTop: homeStationsAtTop)) {
            result.append(Placed(id: "hive", art: art, point: hiveSlot))
        }
        return result
    }
}
