import Foundation
import PofuCore

/// What a critter is. Each sits at a rest spot that reads in a still frame
/// and moves only in Ambient or when brushed (experience v1 §6, rule 3).
public enum CritterKind: String, CaseIterable, Hashable, Sendable {
    case butterfly, snail, bird, frog

    /// The baked sprite's name (a four-frame loop plus a rest pose).
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
        critter("butterfly-west", .butterfly, on: .dressing("meadow-west"), -100, -20, 1...10),
        critter("butterfly-east", .butterfly, on: .dressing("meadow-east-2"), 184, -20, 6...10),
        critter("snail-lip", .snail, on: .lip, -150, 36, 1...10),
        // The tallest roof so far: the garden's, then the windmill's.
        critter("bird-garden", .bird, on: .station(.garden), -173, -52, 1...7),
        critter("bird-windmill", .bird, on: .station(.windmill), -50, -104, 8...10),
        // The frogs arrive with the pond.
        critter("frog-1", .frog, on: .station(.pond), -84, 26, 4...10),
        critter("frog-2", .frog, on: .station(.pond), -46, 24, 4...10),
    ]

    public static func critters(atLevel level: Int) -> [Critter] {
        all.filter { $0.levels.contains(level) }
    }
}
