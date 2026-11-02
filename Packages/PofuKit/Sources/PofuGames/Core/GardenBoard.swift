/// The garden bed: an 8 × 8 grid of soil, each cell empty or planted.
///
/// Stored as a 64-bit mask (bit `row * 8 + column`), so placing a piece,
/// testing a fit and finding full lines are a few integer operations; the
/// fair generator can try every shape at every origin each tray without
/// a measurable cost.
public struct GardenBoard: Hashable, Sendable, CustomStringConvertible {
    public static let size = 8
    public static let cellCount = size * size

    public private(set) var bits: UInt64

    public init(bits: UInt64 = 0) {
        self.bits = bits
    }

    /// A board drawn as eight rows of `#` (planted) and `.` (soil). Rows
    /// may be shorter than eight; missing cells are soil.
    public init(rows: [String]) {
        var bits: UInt64 = 0
        for (row, line) in rows.prefix(Self.size).enumerated() {
            for (column, character) in line.prefix(Self.size).enumerated() where character == "#" {
                bits |= Self.bit(GardenCell(row: row, column: column))
            }
        }
        self.bits = bits
    }

    static func bit(_ cell: GardenCell) -> UInt64 {
        UInt64(1) << UInt64(cell.row * size + cell.column)
    }

    public static func rowMask(_ row: Int) -> UInt64 {
        UInt64(0xFF) << UInt64(row * size)
    }

    public static func columnMask(_ column: Int) -> UInt64 {
        UInt64(0x0101_0101_0101_0101) << UInt64(column)
    }

    public static func contains(_ cell: GardenCell) -> Bool {
        (0..<size).contains(cell.row) && (0..<size).contains(cell.column)
    }

    public static func cells(in mask: UInt64) -> [GardenCell] {
        var result: [GardenCell] = []
        var rest = mask
        while rest != 0 {
            let index = rest.trailingZeroBitCount
            result.append(GardenCell(row: index / size, column: index % size))
            rest &= rest - 1
        }
        return result
    }

    public var description: String {
        (0..<Self.size).map { row in
            String((0..<Self.size).map { isPlanted(GardenCell(row: row, column: $0)) ? "#" : "." })
        }.joined(separator: "\n")
    }

    public var plantedCount: Int { bits.nonzeroBitCount }
    public var isEmpty: Bool { bits == 0 }
    public var plantedCells: [GardenCell] { Self.cells(in: bits) }

    public func isPlanted(_ cell: GardenCell) -> Bool {
        Self.contains(cell) && bits & Self.bit(cell) != 0
    }

    /// The cells `shape` covers with its top-left at `origin`, or `nil`
    /// when part of it would leave the bed.
    public func mask(of shape: PieceShape, at origin: GardenCell) -> UInt64? {
        guard origin.row >= 0, origin.column >= 0,
              origin.row + shape.height <= Self.size,
              origin.column + shape.width <= Self.size
        else { return nil }
        return shape.mask << UInt64(origin.row * Self.size + origin.column)
    }

    public func canPlace(_ shape: PieceShape, at origin: GardenCell) -> Bool {
        guard let mask = mask(of: shape, at: origin) else { return false }
        return bits & mask == 0
    }

    /// Every origin where `shape` fits, top row first.
    public func origins(for shape: PieceShape) -> [GardenCell] {
        var result: [GardenCell] = []
        for row in 0...(Self.size - shape.height) {
            for column in 0...(Self.size - shape.width) {
                let origin = GardenCell(row: row, column: column)
                if canPlace(shape, at: origin) { result.append(origin) }
            }
        }
        return result
    }

    public func fits(_ shape: PieceShape) -> Bool {
        for row in 0...(Self.size - shape.height) {
            for column in 0...(Self.size - shape.width) where canPlace(shape, at: GardenCell(row: row, column: column)) {
                return true
            }
        }
        return false
    }

    /// The rows and columns that would be full with `extra` planted too.
    public func lines(with extra: UInt64 = 0) -> LineSet {
        let filled = bits | extra
        var rows: [Int] = []
        var columns: [Int] = []
        for index in 0..<Self.size {
            let row = Self.rowMask(index)
            if filled & row == row { rows.append(index) }
            let column = Self.columnMask(index)
            if filled & column == column { columns.append(index) }
        }
        return LineSet(rows: rows, columns: columns)
    }

    /// Plants `shape` at `origin` and clears every full row and column at
    /// once (cells where a row and a column cross clear once). Returns
    /// `nil`, changing nothing, when the shape does not fit there.
    public mutating func place(_ shape: PieceShape, at origin: GardenCell) -> (planted: UInt64, cleared: LineSet)? {
        guard let mask = mask(of: shape, at: origin), bits & mask == 0 else { return nil }
        bits |= mask
        let cleared = lines()
        bits &= ~cleared.mask
        return (mask, cleared)
    }

    /// The best origin for `shape` near a fractional top-left position (in
    /// cells), for a forgiving snap: the rounded position if it fits, else
    /// the closest fitting origin within `tolerance` cells, else `nil`.
    public func snap(_ shape: PieceShape, row: Double, column: Double, tolerance: Double = 0.9) -> GardenCell? {
        let rounded = GardenCell(row: Int(row.rounded()), column: Int(column.rounded()))
        if canPlace(shape, at: rounded) { return rounded }
        var best: (origin: GardenCell, distance: Double)?
        for dr in -1...1 {
            for dc in -1...1 where dr != 0 || dc != 0 {
                let origin = GardenCell(row: rounded.row + dr, column: rounded.column + dc)
                guard canPlace(shape, at: origin) else { continue }
                let distance = ((Double(origin.row) - row) * (Double(origin.row) - row)
                    + (Double(origin.column) - column) * (Double(origin.column) - column)).squareRoot()
                if distance <= tolerance, distance < (best?.distance ?? .infinity) {
                    best = (origin, distance)
                }
            }
        }
        return best?.origin
    }

    /// Empty cells with planted cells or the bed's edge on all four sides:
    /// holes nothing but a single sprout can fill. The autoplayer avoids
    /// making them.
    public var holes: Int {
        Self.cells(in: ~bits).filter { cell in
            [(-1, 0), (1, 0), (0, -1), (0, 1)].allSatisfy { dr, dc in
                let neighbour = GardenCell(row: cell.row + dr, column: cell.column + dc)
                return !Self.contains(neighbour) || isPlanted(neighbour)
            }
        }.count
    }
}

/// Full rows and columns, cleared together in one bloom.
public struct LineSet: Hashable, Sendable {
    public var rows: [Int]
    public var columns: [Int]

    public init(rows: [Int] = [], columns: [Int] = []) {
        self.rows = rows
        self.columns = columns
    }

    public static let empty = LineSet()

    public var count: Int { rows.count + columns.count }
    public var isEmpty: Bool { count == 0 }

    /// The cells in these lines, as a mask.
    public var mask: UInt64 {
        rows.reduce(UInt64(0)) { $0 | GardenBoard.rowMask($1) }
            | columns.reduce(UInt64(0)) { $0 | GardenBoard.columnMask($1) }
    }

    public var cells: [GardenCell] { GardenBoard.cells(in: mask) }
}
