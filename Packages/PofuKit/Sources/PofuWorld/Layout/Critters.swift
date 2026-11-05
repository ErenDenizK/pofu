import Foundation
import PofuCore

/// What a critter is. Each sits at a rest spot that reads in a still frame
/// and moves only in Ambient or when brushed (experience v1 §6, rule 3).
public enum CritterKind: String, CaseIterable, Hashable, Sendable {
    case butterfly, snail, bird, frog, ladybug

    /// The baked sprite's name (a four-frame loop plus a rest pose); the
    /// Codex jobs are `critter-butterfly`, `critter-snail`, `critter-bird`,
    /// `critter-ladybug` (and the frog's).
    public var art: String {
        "critter-\(rawValue)"
    }
}

/// What a critter rests on.
public enum CritterPerch: Hashable, Sendable {
    /// A piece of dressing (a butterfly on the wildflowers).
    case dressing(String)
    /// The island's front lip.
    case lip
    /// A station's roof or water: it must be open at the critter's level.
    case station(StationID)
}

public struct Critter: Hashable, Sendable, Identifiable {
    public var id: String
    public var kind: CritterKind
    public var perch: CritterPerch
    /// Where it rests, in world units.
    public var rest: WorldPoint
    /// The island levels it is there for.
    public var levels: ClosedRange<Int>

    /// Whether the rest spot is on the lawn itself, so it holds a cell of
    /// the fullness grid (a bird on a roof does not).
    public var isOnLawn: Bool {
        switch perch {
        case .dressing, .station(.pond): true
        case .lip, .station: false
        }
    }
}

/// The critters of the home island: at most `limit` at once, each at a
/// hand-placed rest spot.
public enum Critters {
    /// They join the characters' pass; more would cost frames.
    public static let limit = 6

    private static func critter(
        _ id: String, _ kind: CritterKind, on perch: CritterPerch, _ x: Double, _ y: Double, _ levels: ClosedRange<Int>
    ) -> Critter {
        Critter(id: id, kind: kind, perch: perch, rest: WorldPoint(x: x, y: y), levels: levels)
    }

    public static let all: [Critter] = [
        critter("butterfly-west", .butterfly, on: .dressing("meadow-west"), -100, -14, 1...10),
        critter("ladybug-east", .ladybug, on: .dressing("meadow-east-2"), 184, -20, 6...10),
        critter("snail-lip", .snail, on: .lip, -150, 36, 1...10),
        // The tallest roof so far: the garden's, then the windmill's.
        critter("bird-garden", .bird, on: .station(.garden), -173, -52, 1...7),
        critter("bird-windmill", .bird, on: .station(.windmill), -90, -104, 8...10),
        // The frogs arrive with the pond.
        critter("frog-1", .frog, on: .station(.pond), -84, 26, 4...10),
        critter("frog-2", .frog, on: .station(.pond), -46, 24, 4...10),
    ]

    public static func critters(atLevel level: Int) -> [Critter] {
        all.filter { $0.levels.contains(level) }
    }
}

/// The lawn's small life as touch props: the dressing that sways and the
/// critters at rest, for the brushing finger (`TouchField`).
public enum IslandLife {
    public static func dressingID(_ piece: DressingPiece) -> String {
        "dressing-\(piece.id)"
    }

    public static func critterID(_ critter: Critter) -> String {
        "critter-\(critter.id)"
    }

    /// What a brush can touch at an island level: the touchable dressing and
    /// every critter, by their feet.
    public static func touchProps(atLevel level: Int) -> [(id: String, base: WorldPoint)] {
        var props: [(id: String, base: WorldPoint)] = []
        for piece in IslandDressing.pieces(atLevel: level) where piece.touchable {
            props.append((id: dressingID(piece), base: piece.point))
        }
        for critter in Critters.critters(atLevel: level) {
            props.append((id: critterID(critter), base: critter.rest))
        }
        return props
    }
}
