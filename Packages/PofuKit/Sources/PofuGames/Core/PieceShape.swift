/// A cell of the garden bed: row 0 is the top row, column 0 the left.
public struct GardenCell: Hashable, Sendable, Comparable, CustomStringConvertible {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public static func < (lhs: GardenCell, rhs: GardenCell) -> Bool {
        (lhs.row, lhs.column) < (rhs.row, rhs.column)
    }

    public var description: String { "(\(row),\(column))" }
}

/// A plot of sprouts: one fixed orientation of a polyomino. Pieces never
/// rotate in play (as in every proven block puzzle: rotation doubles the
/// thinking and halves the pace); orientations are separate shapes.
public struct PieceShape: Hashable, Sendable, Identifiable, CustomStringConvertible {
    /// Family and orientation, such as "L4.2". Stable: tests and replays
    /// name shapes by it.
    public let id: String
    public let family: PieceFamily
    /// The cells, normalised so the top-left of the bounding box is (0, 0),
    /// sorted by row then column.
    public let cells: [GardenCell]
    public let width: Int
    public let height: Int
    /// The cells as a bit mask with the shape's top-left at (0, 0), in the
    /// board's layout (bit `row * 8 + column`).
    public let mask: UInt64

    public var count: Int { cells.count }
    public var description: String { id }

    init(id: String, family: PieceFamily, cells: [GardenCell]) {
        let minRow = cells.map(\.row).min() ?? 0
        let minColumn = cells.map(\.column).min() ?? 0
        let normalised = cells
            .map { GardenCell(row: $0.row - minRow, column: $0.column - minColumn) }
            .sorted()
        self.id = id
        self.family = family
        self.cells = normalised
        self.width = (normalised.map(\.column).max() ?? 0) + 1
        self.height = (normalised.map(\.row).max() ?? 0) + 1
        self.mask = normalised.reduce(UInt64(0)) { $0 | GardenBoard.bit($1) }
    }

    /// A shape drawn as rows of `#` (a sprout) and `.` (empty).
    init(id: String, family: PieceFamily, rows: [String]) {
        var cells: [GardenCell] = []
        for (row, line) in rows.enumerated() {
            for (column, character) in line.enumerated() where character == "#" {
                cells.append(GardenCell(row: row, column: column))
            }
        }
        self.init(id: id, family: family, cells: cells)
    }

    /// The shape turned a quarter clockwise.
    func rotated() -> [GardenCell] {
        cells.map { GardenCell(row: $0.column, column: height - 1 - $0.row) }
    }
}

/// A family of shapes: the polyomino, all its orientations together. The
/// generator picks a family by weight, then an orientation uniformly, so a
/// family with eight orientations is not eight times as common.
public enum PieceFamily: String, CaseIterable, Sendable {
    case single
    case pair
    case line3
    case line4
    case line5
    case corner3
    case square2
    case square3
    case ell4
    case tee4
    case skew4
    case rect6
    case corner5

    /// The family's base shape and how many quarter turns give new shapes.
    var base: [String] {
        switch self {
        case .single: ["#"]
        case .pair: ["##"]
        case .line3: ["###"]
        case .line4: ["####"]
        case .line5: ["#####"]
        case .corner3: ["##", "#."]
        case .square2: ["##", "##"]
        case .square3: ["###", "###", "###"]
        case .ell4: ["#.", "#.", "##"]
        case .tee4: ["###", ".#."]
        case .skew4: [".##", "##."]
        case .rect6: ["###", "###"]
        case .corner5: ["#..", "#..", "###"]
        }
    }

    /// Whether mirror images are distinct shapes worth adding.
    var mirrors: Bool {
        switch self {
        case .ell4, .skew4: true
        default: false
        }
    }

    /// Relative frequency in a fresh garden, tuned so a tray usually holds
    /// one small, one medium and one large piece. Tunable; see
    /// docs/product/minigames.md.
    public var weight: Int {
        switch self {
        case .single: 4
        case .pair: 10
        case .line3: 10
        case .line4: 7
        case .line5: 4
        case .corner3: 10
        case .square2: 8
        case .square3: 3
        case .ell4: 9
        case .tee4: 6
        case .skew4: 4
        case .rect6: 4
        case .corner5: 4
        }
    }

    /// The tint the scene paints this family's sprouts with (an index into
    /// the garden palette), so the same shape always wears the same colour.
    public var tint: Int {
        switch self {
        case .single, .square3: 0
        case .pair, .ell4: 1
        case .line3, .line5, .rect6: 2
        case .line4, .skew4: 3
        case .corner3, .corner5: 4
        case .square2, .tee4: 5
        }
    }
}

public enum PieceCatalog {
    /// Every shape, in a stable order: families in declaration order, each
    /// with its distinct orientations.
    public static let all: [PieceShape] = PieceFamily.allCases.flatMap { PieceCatalog.shapes(of: $0) }

    /// The distinct orientations of a family.
    public static func shapes(of family: PieceFamily) -> [PieceShape] {
        var seen = Set<UInt64>()
        var result: [PieceShape] = []
        var bases = [PieceShape(id: family.rawValue, family: family, rows: family.base)]
        if family.mirrors {
            let mirrored = family.base.map { String($0.reversed()) }
            bases.append(PieceShape(id: family.rawValue, family: family, rows: mirrored))
        }
        for base in bases {
            var shape = base
            for _ in 0..<4 {
                if seen.insert(shape.mask).inserted {
                    result.append(PieceShape(id: "\(family.rawValue).\(result.count)", family: family, cells: shape.cells))
                }
                shape = PieceShape(id: family.rawValue, family: family, cells: shape.rotated())
            }
        }
        return result
    }

    public static func shape(id: String) -> PieceShape? {
        all.first { $0.id == id }
    }
}
