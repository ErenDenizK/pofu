import Foundation

/// The names of the flow board's painted art, written by
/// `tools/art/ingest_flow_board_kit.py`. Every file is required: a missing
/// one is a test failure (`FlowGroundTests`), never a silent fallback to a
/// drawing.
///
/// A piece that turns (straight, bend, split) is a round dial laid on a
/// `socket` block; a piece that does not turn is a block with its feature
/// painted on it. A bed is the painted channel's outline, which the code
/// fills with water.
public enum FlowArtSlot {
    /// The painted scene behind the board: a rock and a fall above, the lawn plate the board sits on, a round pool below.
    public static let backdrop = "flow-backdrop"
    /// The seamless water the code fills the beds with.
    public static let water = "flow-water"
    /// The mill wheel that turns over the wheel block's hub.
    public static let wheel = "flow-wheel"
    /// The kit's numbers (plate, canvas), a JSON file read by `FlowKit`.
    public static let kit = "flow-kit"

    public static let blocks = ["plain", "flowers", "rock", "socket", "spring", "goal", "wheel", "gate"]
    public static let dials = ["straight", "bend", "split"]
    public static let beds = ["straight", "bend", "split", "spring", "goal", "wheel", "gate"]

    public static func block(_ name: String) -> String { "flow-block-\(name)" }
    public static func dial(_ name: String) -> String { "flow-dial-\(name)" }
    public static func bed(_ name: String) -> String { "flow-bed-\(name)" }

    /// The block a kind sits on: its own painted block, or the socket under a dial; grass is plain or, as an accent, flowers.
    public static func blockName(of kind: FlowTileKind, flowered: Bool = false) -> String {
        switch kind {
        case .straight, .bend, .split: block("socket")
        case .source: block("spring")
        case .mouth: block("goal")
        case .wheel: block("wheel")
        case .gate: block("gate")
        case .rock: block("rock")
        case .grass: block(flowered ? "flowers" : "plain")
        }
    }

    /// The dial a turnable kind wears, nil for a fixed kind.
    public static func dialName(of kind: FlowTileKind) -> String? {
        switch kind {
        case .straight: dial("straight")
        case .bend: dial("bend")
        case .split: dial("split")
        default: nil
        }
    }

    /// The water's bed in a kind's painted piece, nil for a kind with no channel.
    public static func bedName(of kind: FlowTileKind) -> String? {
        switch kind {
        case .straight: bed("straight")
        case .bend: bed("bend")
        case .split: bed("split")
        case .source: bed("spring")
        case .mouth: bed("goal")
        case .wheel: bed("wheel")
        case .gate: bed("gate")
        case .rock, .grass: nil
        }
    }

    /// Every PNG the board loads.
    public static var required: [String] {
        [backdrop, water, wheel] + blocks.map(block) + dials.map(dial) + beds.map(bed)
    }
}

/// The numbers `tools/art/ingest_flow_board_kit.py` measured on the kit, so a
/// repainted piece or backdrop is swapped in by running the tool again.
public struct FlowKit: Decodable, Sendable, Equatable {
    public struct Plate: Decodable, Sendable, Equatable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double
    }

    /// The backdrop's lawn plate, as fractions of the picture.
    public let plate: Plate
    /// The backdrop's width over its height.
    public let aspect: Double
    /// A piece's square canvas in pixels: one cell.
    public let canvas: Int
    /// A block's body and a dial's rimless grass disc, as fractions of the cell.
    public let body: Double
    public let disc: Double

    public static let shared: FlowKit = {
        guard let url = Bundle.module.url(forResource: FlowArtSlot.kit, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let kit = try? JSONDecoder().decode(FlowKit.self, from: data)
        else { preconditionFailure("flow-kit.json is missing or unreadable") }
        return kit
    }()
}

/// Which grass cells wear the flowers block: an accent, never two neighbours
/// in a row or a column, and the same on every run.
public struct FlowVariantPicker: Sendable {
    public init(board: FlowBoard) {}

    private func hash(_ cell: FlowCell, _ salt: Int) -> Int {
        var value = (cell.row &* 73856093) ^ (cell.column &* 19349663) ^ (salt &* 83492791)
        value = (value ^ (value >> 13)) &* 1274126177
        return (value ^ (value >> 16)) & 0x7FFF_FFFF
    }

    private func seeds(_ cell: FlowCell) -> Bool { hash(cell, 4) % 5 == 0 }

    public func flowered(_ cell: FlowCell) -> Bool {
        seeds(cell)
            && !seeds(FlowCell(row: cell.row, column: cell.column - 1))
            && !seeds(FlowCell(row: cell.row - 1, column: cell.column))
    }
}
