/// A square-grid board of tiles, read from and written to the glyph rows
/// of `docs/design/flow-game.md` (`"┘ └ #"`: tiles separated by spaces).
public struct FlowBoard: Hashable, Sendable {
    public let columns: Int
    public let rows: Int
    public private(set) var tiles: [FlowTile]

    /// Parses glyph rows; nil on a ragged or unknown glyph.
    public init?(rows lines: [String]) {
        let parsed = lines.map { $0.split(separator: " ").map { $0.count == 1 ? $0.first : nil } }
        guard let width = parsed.first?.count, width > 0, parsed.allSatisfy({ $0.count == width }) else { return nil }
        var tiles: [FlowTile] = []
        for row in parsed {
            for glyph in row {
                guard let glyph, let tile = FlowTile(glyph: glyph) else { return nil }
                tiles.append(tile)
            }
        }
        columns = width
        rows = parsed.count
        self.tiles = tiles
    }

    public var glyphRows: [String] {
        (0..<rows).map { row in
            (0..<columns).map { String(tiles[row * columns + $0].glyph) }.joined(separator: " ")
        }
    }

    public func contains(_ cell: FlowCell) -> Bool {
        cell.row >= 0 && cell.row < rows && cell.column >= 0 && cell.column < columns
    }

    public subscript(cell: FlowCell) -> FlowTile? {
        contains(cell) ? tiles[cell.row * columns + cell.column] : nil
    }

    public var allCells: [FlowCell] {
        (0..<rows).flatMap { row in (0..<columns).map { FlowCell(row: row, column: $0) } }
    }

    public func cells(of kind: FlowTileKind) -> [FlowCell] {
        allCells.filter { self[$0]?.kind == kind }
    }

    public var turnableCells: [FlowCell] { allCells.filter { self[$0]?.kind.isTurnable == true } }
    public var targets: [FlowCell] { allCells.filter { self[$0]?.kind.isTarget == true } }

    /// Turns the tile at `cell` one quarter clockwise. False (and no
    /// change) for a fixed tile or a cell off the board.
    @discardableResult
    public mutating func rotate(at cell: FlowCell) -> Bool {
        guard let tile = self[cell], !tile.isFixed else { return false }
        tiles[cell.row * columns + cell.column] = tile.rotatedClockwise
        return true
    }

    mutating func set(_ tile: FlowTile, at cell: FlowCell) {
        guard contains(cell) else { return }
        tiles[cell.row * columns + cell.column] = tile
    }
}

extension FlowBoard: Codable {
    public init(from decoder: Decoder) throws {
        let rows = try decoder.singleValueContainer().decode([String].self)
        guard let board = FlowBoard(rows: rows) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad flow board rows"))
        }
        self = board
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(glyphRows)
    }
}
