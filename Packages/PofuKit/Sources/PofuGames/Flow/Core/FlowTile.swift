/// One side of a tile. A tile's openings are a set of these.
public struct FlowDirection: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let north = FlowDirection(rawValue: 1)
    public static let east = FlowDirection(rawValue: 2)
    public static let south = FlowDirection(rawValue: 4)
    public static let west = FlowDirection(rawValue: 8)

    /// The four single sides, clockwise from north.
    public static let sides: [FlowDirection] = [.north, .east, .south, .west]

    /// Every opening turned 90° clockwise (N→E→S→W→N).
    public var rotatedClockwise: FlowDirection {
        var result: FlowDirection = []
        if contains(.north) { result.insert(.east) }
        if contains(.east) { result.insert(.south) }
        if contains(.south) { result.insert(.west) }
        if contains(.west) { result.insert(.north) }
        return result
    }

    /// The side facing this one on the neighbouring tile.
    public var opposite: FlowDirection {
        var result: FlowDirection = []
        if contains(.north) { result.insert(.south) }
        if contains(.south) { result.insert(.north) }
        if contains(.east) { result.insert(.west) }
        if contains(.west) { result.insert(.east) }
        return result
    }

    /// The row and column step toward this (single) side.
    var step: (row: Int, column: Int) {
        if contains(.north) { return (-1, 0) }
        if contains(.east) { return (0, 1) }
        if contains(.south) { return (1, 0) }
        return (0, -1)
    }

    public var names: [String] {
        Self.sides.filter { contains($0) }.map { side in
            switch side {
            case .north: "north"
            case .east: "east"
            case .south: "south"
            default: "west"
            }
        }
    }
}

public enum FlowTileKind: String, Sendable, Codable, CaseIterable {
    case straight, bend, split, source, mouth, wheel, gate, rock, grass

    /// Openings at rotation 0: `│`, `└`, `├`, the source opens south, the
    /// mouth north, the wheel east-west, the gate as `│`.
    var baseOpenings: FlowDirection {
        switch self {
        case .straight, .gate: [.north, .south]
        case .bend: [.north, .east]
        case .split: [.north, .east, .south]
        case .source: .south
        case .mouth: .north
        case .wheel: [.east, .west]
        case .rock, .grass: []
        }
    }

    /// Whether a tap turns it.
    public var isTurnable: Bool {
        switch self {
        case .straight, .bend, .split: true
        default: false
        }
    }

    /// A target the board needs wet to be solved.
    public var isTarget: Bool { self == .mouth || self == .wheel }

    /// Distinct rotations: a straight has two, bends and splits four.
    public var stateCount: Int {
        switch self {
        case .straight: 2
        case .bend, .split: 4
        default: 1
        }
    }
}

/// A cell on the board, row 0 at the top.
public struct FlowCell: Hashable, Sendable, Comparable, Codable {
    public var row: Int
    public var column: Int
    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public static func < (a: FlowCell, b: FlowCell) -> Bool {
        (a.row, a.column) < (b.row, b.column)
    }

    func neighbour(_ side: FlowDirection) -> FlowCell {
        let step = side.step
        return FlowCell(row: row + step.row, column: column + step.column)
    }
}

/// A tile: its kind and how far it is turned. Fixed tiles never turn.
public struct FlowTile: Hashable, Sendable {
    public let kind: FlowTileKind
    /// Quarter turns clockwise, below `kind.stateCount`.
    public private(set) var rotation: Int

    public init(kind: FlowTileKind, rotation: Int = 0) {
        self.kind = kind
        self.rotation = ((rotation % kind.stateCount) + kind.stateCount) % kind.stateCount
    }

    public var isFixed: Bool { !kind.isTurnable }

    public var openings: FlowDirection {
        var result = kind.baseOpenings
        for _ in 0..<rotation { result = result.rotatedClockwise }
        return result
    }

    /// One tap: 90° clockwise. A fixed tile does not move.
    public var rotatedClockwise: FlowTile {
        guard !isFixed else { return self }
        return FlowTile(kind: kind, rotation: rotation + 1)
    }

    /// The tile after `taps` taps.
    func rotated(by taps: Int) -> FlowTile {
        FlowTile(kind: kind, rotation: rotation + taps)
    }

    /// Taps needed to turn this tile into `other` (same kind), 0 if equal.
    func taps(to other: FlowTile) -> Int {
        ((other.rotation - rotation) % kind.stateCount + kind.stateCount) % kind.stateCount
    }

    // MARK: Glyphs

    private static let table: [(Character, FlowTileKind, Int)] = [
        ("│", .straight, 0), ("─", .straight, 1),
        ("└", .bend, 0), ("┌", .bend, 1), ("┐", .bend, 2), ("┘", .bend, 3),
        ("├", .split, 0), ("┬", .split, 1), ("┤", .split, 2), ("┴", .split, 3),
        ("S", .source, 0), ("P", .mouth, 0), ("W", .wheel, 0), ("G", .gate, 0),
        ("#", .rock, 0), (".", .grass, 0),
    ]

    public init?(glyph: Character) {
        guard let entry = Self.table.first(where: { $0.0 == glyph }) else { return nil }
        self.init(kind: entry.1, rotation: entry.2)
    }

    public var glyph: Character {
        Self.table.first { $0.1 == kind && $0.2 == rotation }?.0 ?? "?"
    }
}
