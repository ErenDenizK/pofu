import Foundation
import PofuCore

/// What a piece of the island's growth is (home progression §3, home layout
/// §4 and §9). Each is one painted sprite named `art` when the pipeline has
/// one; until then the scene draws a code-drawn stand-in (`GrowthArt`), so
/// the Codex queue can replace them one by one without touching the scene.
public enum GrowthKind: String, CaseIterable, Hashable, Sendable {
    /// IL2: a flat stone of the path to the tea corner.
    case pathStone
    /// IL3: the harbor's striped flag pole at the lawn's right end.
    case flagPole
    /// IL3: a gull gliding in the sky over the harbor side.
    case gull
    /// IL2: the kettle's steam over the tea stall.
    case steam
    /// IL3: the rope bridge leaving the lawn's right tip toward İskele.
    case bridge
    /// IL4: a lily pad on the pond (the first carries a lotus).
    case lilyPad
    /// IL4: cattails at the pond's rim.
    case reeds
    /// IL5: a round mossy stepping stone toward the pond.
    case steppingStone
    /// IL5: a dragonfly over the pond.
    case dragonfly
    /// IL6: the back terrace, a grassy rise behind the workshop.
    case terrace
    /// IL8: a string of paper lanterns along the terrace.
    case lanternString
    /// IL9: a stone of the hill path.
    case hillStone
    /// IL9: the gate with a carved sunflower and a soft glow behind it.
    case gate
    /// IL10: the hilltop terrace above the gate, with its tree.
    case hilltop
    /// IL10: the bench on the hilltop (the painted `decor-bench`).
    case bench

    /// The baked sprite's name.
    public var art: String {
        if self == .bench { return "decor-bench" }
        var stem = ""
        for character in rawValue {
            if character.isUppercase { stem.append("-") }
            stem.append(contentsOf: character.lowercased())
        }
        return "growth-\(stem)"
    }

    /// Whether it lies flat on the lawn, under everything that stands near.
    public var isFlat: Bool {
        switch self {
        case .pathStone, .steppingStone, .hillStone: true
        default: false
        }
    }

    /// Whether it moves by itself in Ambient.
    public var moves: Bool {
        switch self {
        case .gull, .steam, .dragonfly, .reeds, .lanternString, .flagPole, .lilyPad, .gate, .terrace, .hilltop: true
        default: false
        }
    }
}

/// One piece of growth: what, where (its feet, world units) and the island
/// level it first appears at. A piece never leaves (the island only grows).
public struct GrowthPiece: Hashable, Sendable, Identifiable {
    public var id: String
    public var kind: GrowthKind
    public var variant: Int
    public var point: WorldPoint
    public var from: Int

    public var art: String { kind.art }

    public func isShown(atLevel level: Int) -> Bool {
        level >= from
    }

    /// A stable per-piece phase for motion, 0...2π.
    public var phase: Double {
        let sum = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 9973 }
        return Double(sum) / 9973 * 2 * .pi
    }

    /// The painter's-order depth: flat things lie under what stands at the
    /// same row; the terraces sit behind everything; the sky's gulls behind
    /// those.
    public var depth: Double {
        switch kind {
        case .gull, .dragonfly: kind == .gull ? -400 : IslandLayout.depth(ofY: point.y) + 20
        case .hilltop: -260
        case .terrace: -200
        case .lanternString, .gate: IslandLayout.depth(ofY: point.y) - 4
        case .lilyPad: IslandLayout.depth(ofY: point.y) + 6
        case .steam: IslandLayout.depth(ofY: point.y) + 1
        default: kind.isFlat ? IslandLayout.depth(ofY: point.y) - 40 : IslandLayout.depth(ofY: point.y)
        }
    }
}

/// The home island's growth, authored by hand level by level so every island
/// level is a visible change at the Home framing (the founder's rule: every
/// level is a living step). Positions are world units on the lawn
/// (`IslandLayout`); ground pieces stay inside the walkable lawn
/// (`IslandGrowthTests`). The plate never changes shape: the terraces are
/// drawn over the sky behind the lawn, not as new plate.
public enum IslandGrowth {
    private static func piece(
        _ id: String, _ kind: GrowthKind, _ x: Double, _ y: Double, from: Int, variant: Int = 0
    ) -> GrowthPiece {
        GrowthPiece(id: id, kind: kind, variant: variant, point: WorldPoint(x: x, y: y), from: from)
    }

    /// The stones of the path from Pofu's spot to the tea corner.
    static let pathStones: [(Double, Double)] = [
        (48, 35), (68, 38), (90, 39), (111, 37), (130, 31), (144, 23), (152, 15),
    ]
    /// The stepping stones from Pofu toward the pond.
    static let steppingStones: [(Double, Double)] = [(6, 37), (-12, 40), (-32, 41), (-52, 39)]
    /// The hill path from the back lawn up to the gate.
    static let hillStones: [(Double, Double)] = [(104, -24), (108, -31), (110, -38), (112, -45)]

    public static let pieces: [GrowthPiece] = {
        var all: [GrowthPiece] = []
        for (i, p) in pathStones.enumerated() {
            all.append(piece("path-\(i + 1)", .pathStone, p.0, p.1, from: 2, variant: i))
        }
        all.append(piece("kettle-steam", .steam, 150, -30, from: 2))
        all.append(piece("harbor-flag", .flagPole, 176, 22, from: 3))
        all.append(piece("rope-bridge", .bridge, 236, 10, from: 3))
        all.append(piece("gull-1", .gull, 150, -128, from: 3))
        all.append(piece("gull-2", .gull, 186, -108, from: 3, variant: 1))
        all.append(piece("lily-1", .lilyPad, -72, 22, from: 4))
        all.append(piece("lily-2", .lilyPad, -57, 26, from: 4, variant: 1))
        all.append(piece("lily-3", .lilyPad, -76, 29, from: 4, variant: 2))
        all.append(piece("reeds-west", .reeds, -112, 22, from: 4))
        all.append(piece("reeds-east", .reeds, -22, 21, from: 4, variant: 1))
        for (i, p) in steppingStones.enumerated() {
            all.append(piece("step-\(i + 1)", .steppingStone, p.0, p.1, from: 5, variant: i))
        }
        all.append(piece("dragonfly", .dragonfly, -60, -10, from: 5))
        all.append(piece("terrace", .terrace, 50, -50, from: 6))
        all.append(piece("lanterns", .lanternString, 52, -50, from: 8))
        for (i, p) in hillStones.enumerated() {
            all.append(piece("hill-\(i + 1)", .hillStone, p.0, p.1, from: 9, variant: i))
        }
        all.append(piece("gate", .gate, 114, -52, from: 9))
        all.append(piece("hilltop", .hilltop, 92, -78, from: 10))
        all.append(piece("hilltop-bench", .bench, 76, -82, from: 10))
        return all
    }()

    /// The pieces shown at an island level.
    public static func pieces(atLevel level: Int) -> [GrowthPiece] {
        pieces.filter { $0.isShown(atLevel: level) }
    }

    /// The pieces that first appear at an island level.
    public static func arriving(atLevel level: Int) -> [GrowthPiece] {
        pieces.filter { $0.from == level }
    }

    /// Where a moving piece is at `time` seconds (0 at rest): its offset in
    /// world units and its rotation in degrees. Pure, so a still frame and
    /// Reduce Motion draw the rest pose.
    public static func motion(of piece: GrowthPiece, at time: Double) -> (dx: Double, dy: Double, degrees: Double) {
        guard time > 0, piece.kind.moves else { return (0, 0, 0) }
        let p = piece.phase
        switch piece.kind {
        case .gull:
            let t = time * 0.22 + p
            return (22 * sin(t), 5 * sin(t * 2), 8 * cos(t))
        case .dragonfly:
            let t = time * 0.9 + p
            return (16 * sin(t), 7 * sin(t * 1.7), 0)
        case .lanternString:
            return (0, 0, 1.2 * sin(time * 0.9 + p))
        case .lilyPad:
            return (0.6 * sin(time * 0.6 + p), 0.4 * sin(time * 0.8 + p), 0)
        default:
            return (0, 0, 0)
        }
    }
}
