import Foundation
import PofuCore

/// What a piece of dressing is (experience v1 §6). All three families are
/// shipped as sheets cut into baked sprites (`dressing-meadow`,
/// `dressing-garden`, `dressing-harbor`); the scene draws a code-drawn
/// stand-in only for a piece whose sprite is missing from the bundle.
public enum DressingKind: String, CaseIterable, Hashable, Sendable {
    // Meadow
    case grassTuft, wildflowers, pebbles, mushroomRing
    // Garden
    case wateringCan, seedSack, twine, crate, trowel
    // Harbor
    case rope, barrel

    public enum Family: String, Hashable, Sendable {
        case meadow, garden, harbor

        /// The Codex job that paints the family's pieces.
        public var job: String {
            "dressing-\(rawValue)"
        }
    }

    public var family: Family {
        switch self {
        case .grassTuft, .wildflowers, .pebbles, .mushroomRing: .meadow
        case .wateringCan, .seedSack, .twine, .crate, .trowel: .garden
        case .rope, .barrel: .harbor
        }
    }

    /// How many painted variants the kind has: the meadow sheet holds three
    /// tufts and a clover, three flower clumps and a foxglove, a pebble
    /// group, a flat stone and a mossy stone, and one toadstool ring; the
    /// garden's sheet a single crate and a stack of two.
    public var variantCount: Int {
        switch self {
        case .grassTuft, .wildflowers: 4
        case .pebbles: 3
        case .crate: 2
        default: 1
        }
    }

    /// The baked sprite's name for the kind's first variant.
    public var art: String {
        art(variant: 0)
    }

    /// The baked sprite's name for a variant: the first is the bare name
    /// (`dressing-grass-tuft`), the others carry their number from 2
    /// (`dressing-grass-tuft-2`). A variant past the last wraps round.
    public func art(variant: Int) -> String {
        var stem = ""
        for character in rawValue {
            if character.isUppercase { stem.append("-") }
            stem.append(contentsOf: character.lowercased())
        }
        let shown = ((variant % variantCount) + variantCount) % variantCount
        return shown == 0 ? "dressing-\(stem)" : "dressing-\(stem)-\(shown + 1)"
    }
}

/// One hand-placed piece on the home lawn: what, where, and the island
/// levels it is there for.
public struct DressingPiece: Hashable, Sendable, Identifiable {
    public var id: String
    public var kind: DressingKind
    /// Which of the kind's painted variants it wears (`DressingKind.art(variant:)`).
    public var variant: Int
    /// Its feet, in world units.
    public var point: WorldPoint
    /// The island levels it is shown at. A piece that waits on a slot leaves
    /// in the reveal's puff when the slot opens.
    public var levels: ClosedRange<Int>
    /// Whether a tap or a brush can move it (a sway, a rustle); it never
    /// does anything else.
    public var touchable: Bool

    /// The baked sprite's name.
    public var art: String {
        kind.art(variant: variant)
    }

    public func isShown(atLevel level: Int) -> Bool {
        levels.contains(level)
    }
}

/// The home lawn's dressing, authored by hand per slot and level (the
/// founder's craft rule: no procedural scatter). `IslandFullnessTests` holds
/// the rule that no 40-unit cell of the lawn is bare at any island level.
public enum IslandDressing {
    /// Cells of the fullness grid, in world units.
    public static let cellSize = 40.0
    /// A station's or character's ground must cover this much of a cell, in
    /// both directions, to count as holding something.
    public static let minimumOverlap = 10.0

    private static func piece(
        _ id: String,
        _ kind: DressingKind,
        _ x: Double,
        _ y: Double,
        _ levels: ClosedRange<Int>,
        variant: Int = 0,
        touchable: Bool = false
    ) -> DressingPiece {
        DressingPiece(id: id, kind: kind, variant: variant, point: WorldPoint(x: x, y: y), levels: levels, touchable: touchable)
    }

    /// Every piece, grouped by what it dresses.
    public static let pieces: [DressingPiece] = [
        // The meadow between the slots: always there.
        piece("meadow-west", .wildflowers, -100, -8, 1...10, touchable: true),
        piece("meadow-east-1", .grassTuft, 140, -18, 1...10, variant: 1, touchable: true),
        piece("meadow-east-2", .wildflowers, 184, -16, 1...10, variant: 2, touchable: true),
        // The tea stall's slot, until it opens at island level 2.
        piece("tea-ring", .mushroomRing, 150, 6, 1...1, touchable: true),
        // The pond's slot, until it opens at island level 4.
        piece("pond-flowers", .wildflowers, -90, 24, 1...3, variant: 1, touchable: true),
        piece("pond-pebbles", .pebbles, -62, 27, 1...3, variant: 2),
        piece("pond-tuft", .grassTuft, -34, 22, 1...3, touchable: true),
        // The workshop's slot, until it opens at island level 6.
        piece("workshop-trowel", .trowel, 4, -6, 1...5),
        piece("workshop-twine", .twine, -36, -12, 1...5),
        piece("workshop-crate", .crate, 64, -8, 1...5),
        // The windmill's slot, until it opens at island level 8.
        piece("windmill-flowers", .wildflowers, -98, -26, 1...7, variant: 3, touchable: true),
        piece("windmill-ring", .mushroomRing, -70, -24, 1...7, touchable: true),
        // The garden's and the tea stall's small signs of life grow in.
        piece("garden-can", .wateringCan, -118, -4, 3...10),
        piece("garden-sack", .seedSack, -120, 12, 5...10),
        piece("tea-crate", .crate, 205, -4, 3...10, variant: 1),
        piece("tea-flowers", .wildflowers, 200, 12, 6...10, variant: 1, touchable: true),
        // The harbor's first dressing waits at the bridge's foot from IL3.
        piece("bridge-rope", .rope, 222, 4, 3...10),
        piece("bridge-barrel", .barrel, 214, -10, 3...10),
        // They leave in the reveal's puff when the hive's slot opens at IL9.
        piece("gap-flowers", .wildflowers, 80, -16, 5...8, variant: 2, touchable: true),
        // The back lawn between the workshop and the tea stall.
        piece("meadow-back-1", .grassTuft, 62, -22, 1...10, variant: 2, touchable: true),
        piece("meadow-back-2", .grassTuft, 102, -22, 1...10, variant: 3, touchable: true),
        // A flat stone and a few pebbles in the middle lawn, between the pond's slot and Pofu.
        piece("meadow-stone", .pebbles, -8, 12, 1...10, variant: 1),
        piece("meadow-pebbles", .pebbles, 46, 8, 1...10),
    ]

    /// The pieces shown at an island level.
    public static func pieces(atLevel level: Int) -> [DressingPiece] {
        pieces.filter { $0.isShown(atLevel: level) }
    }

    public static func piece(_ id: String) -> DressingPiece? {
        pieces.first { $0.id == id }
    }

    /// The pieces that leave when the island rises from `old` to `new`: they
    /// were shown at the old level and are gone at the new one (their slot
    /// opened). Going down or staying leaves nothing.
    public static func leaving(fromLevel old: Int, toLevel new: Int) -> [DressingPiece] {
        guard new > old else { return [] }
        return pieces.filter { $0.isShown(atLevel: old) && !$0.isShown(atLevel: new) }
    }
}

/// The reveal's puff (experience v1 §6, rule 2): a piece of dressing whose
/// slot has opened leaves in a soft puff instead of vanishing.
public enum DressingReveal {
    /// How long the puff lasts, in seconds.
    public static let puffSeconds = 0.6

    /// The leaving piece and its puff at `elapsed` seconds into the leave.
    /// `scale` and `opacity` are the piece's; `puffRadius` (world units) and
    /// `puffOpacity` the cloud's. Done (nothing drawn) from `puffSeconds`.
    public static func frame(elapsed: Double) -> (scale: Double, opacity: Double, puffRadius: Double, puffOpacity: Double)? {
        guard elapsed >= 0, elapsed < puffSeconds else { return nil }
        let p = elapsed / puffSeconds
        return (
            scale: 1 - 0.55 * p,
            opacity: 1 - p * p,
            puffRadius: 6 + 16 * p,
            puffOpacity: sin(p * .pi) * 0.85
        )
    }
}

/// The 40 × 40-unit grid over the lawn polygon: at every island level every
/// cell holds something drawn (experience v1 §6, rule 1).
public enum IslandFullness {
    /// A thing that holds ground in a cell.
    public struct Holder: Hashable, Sendable {
        public var id: String
        /// The ground it covers, absolute.
        public var ground: WorldBox
        /// Whether a single point (dressing, a critter) holds the cell, or
        /// the ground must overlap it by `IslandDressing.minimumOverlap`.
        public var isPoint: Bool
    }

    public struct Cell: Hashable, Sendable {
        public var column: Int
        public var row: Int
        public var box: WorldBox
    }

    /// The cells whose centre lies on the walkable lawn.
    public static var cells: [Cell] {
        guard let walkable = IslandFootprint.walkable, let bounds = walkable.bounds else { return [] }
        let size = IslandDressing.cellSize
        var result: [Cell] = []
        let firstColumn = Int((bounds.minX / size).rounded(.down)), lastColumn = Int((bounds.maxX / size).rounded(.up))
        let firstRow = Int((bounds.minY / size).rounded(.down)), lastRow = Int((bounds.maxY / size).rounded(.up))
        for row in firstRow..<lastRow {
            for column in firstColumn..<lastColumn {
                let box = WorldBox(
                    minX: Double(column) * size, minY: Double(row) * size,
                    maxX: Double(column + 1) * size, maxY: Double(row + 1) * size
                )
                if walkable.contains(WorldPoint(x: box.midX, y: box.midY)) {
                    result.append(Cell(column: column, row: row, box: box))
                }
            }
        }
        return result
    }

    /// The home stations open at an island level.
    public static func openStations(atLevel level: Int, catalog: ArchipelagoCatalog = .standard) -> [StationID] {
        catalog.stations(on: catalog.home).filter { $0.opensAt <= level }.map(\.id)
    }

    /// The home station whose faint sketch shows at an island level: the
    /// very next one to open.
    public static func sketchedStation(atLevel level: Int, catalog: ArchipelagoCatalog = .standard) -> StationID? {
        catalog.stations(on: catalog.home).filter { $0.opensAt > level }.min { $0.opensAt < $1.opensAt }?.id
    }

    /// The ground of a station slot: its build spot and its first level's
    /// art.
    static func ground(of station: StationID) -> WorldBox? {
        guard let anchor = IslandLayout.stationAnchors[station] else { return nil }
        var points = IslandFootprint.buildSpot.points
        if let art = IslandLayout.stationArt(station, level: 1)?.name {
            points += IslandFootprint.footprint(of: art).points
        }
        return WorldPolygon(points).offset(by: anchor).bounds
    }

    /// Everything that holds ground at an island level.
    public static func holders(atLevel level: Int) -> [Holder] {
        var result: [Holder] = []
        // The hive on the back lawn (home layout S6) from the island level it opens at.
        if let art = HomeFixtures.hiveArt(level: HomeFixtures.hiveLevel(islandLevel: level, homeStationsAtTop: false)),
           let box = WorldPolygon(IslandFootprint.footprint(of: art).points).offset(by: HomeFixtures.hiveSlot).bounds {
            result.append(Holder(id: "hive", ground: box, isPoint: false))
        }
        for station in openStations(atLevel: level) + [sketchedStation(atLevel: level)].compactMap({ $0 }) {
            if let box = ground(of: station) {
                result.append(Holder(id: "station \(station)", ground: box, isPoint: false))
            }
        }
        for resident in IslandLayout.residents {
            if let box = WorldPolygon(IslandFootprint.footprint(of: resident.art).points).offset(by: resident.feet).bounds {
                result.append(Holder(id: "resident \(resident.id)", ground: box, isPoint: false))
            }
        }
        if let box = WorldPolygon(IslandFootprint.footprint(of: "pofu").points).offset(by: IslandLayout.pofu).bounds {
            result.append(Holder(id: "pofu", ground: box, isPoint: false))
        }
        for piece in IslandDressing.pieces(atLevel: level) {
            result.append(Holder(id: "dressing \(piece.id)", ground: point(piece.point), isPoint: true))
        }
        for critter in Critters.critters(atLevel: level) where critter.isOnLawn {
            result.append(Holder(id: "critter \(critter.id)", ground: point(critter.rest), isPoint: true))
        }
        return result
    }

    private static func point(_ p: WorldPoint) -> WorldBox {
        WorldBox(minX: p.x, minY: p.y, maxX: p.x, maxY: p.y)
    }

    /// Whether `holder` holds `cell`.
    public static func holds(_ holder: Holder, _ cell: Cell) -> Bool {
        let g = holder.ground, c = cell.box
        if holder.isPoint {
            return g.minX >= c.minX && g.minX < c.maxX && g.minY >= c.minY && g.minY < c.maxY
        }
        let overlapX = min(g.maxX, c.maxX) - max(g.minX, c.minX)
        let overlapY = min(g.maxY, c.maxY) - max(g.minY, c.minY)
        return overlapX >= IslandDressing.minimumOverlap && overlapY >= IslandDressing.minimumOverlap
    }

    /// The cells nothing holds at an island level.
    public static func bareCells(atLevel level: Int) -> [Cell] {
        let all = holders(atLevel: level)
        return cells.filter { cell in !all.contains { holds($0, cell) } }
    }
}
