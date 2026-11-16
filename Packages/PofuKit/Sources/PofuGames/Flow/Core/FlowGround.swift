import Foundation

/// How the flow board's banks are laid. Method B, the default, lays one
/// seamless lawn under the whole board, with the stones as keycaps on it and
/// the rocks as cut-out pieces: only what the player can touch is raised, so
/// the ground reads as ground. Method A gives every bank cell its own inset
/// keycap square; it stays as a switch for comparison frames.
public enum FlowGroundMethod: String, Sendable, CaseIterable {
    case keycaps
    case lawn
}

/// The switch itself. `POFU_FLOW_GROUND=keycaps` in the launch environment
/// selects method A; a screenshot test sets `method` directly.
public enum FlowGroundSettings {
    @MainActor public static var method: FlowGroundMethod = {
        ProcessInfo.processInfo.environment["POFU_FLOW_GROUND"].flatMap(FlowGroundMethod.init(rawValue:)) ?? .lawn
    }()
}

/// The names of the flow board's painted art slots. Each slot is looked up
/// in the bundle; a missing file means the drawing stays. Variants of a slot
/// are `name`, `name-2`, `name-3`, and so on.
public enum FlowArtSlot {
    public static let grass = "flow-grass"
    public static let rock = "flow-rock"
    /// Method B: the rock as a cut-out piece (transparent around it).
    public static let rockCut = "flow-rock-cut"
    /// The top lip kit (batch 135): two ends, a run stone and the spillway, set over the backdrop's cascade.
    public static let lipEndLeft = "flow-lip-end-left"
    public static let lipRun = "flow-lip-run"
    public static let lipSpill = "flow-lip-spill"
    public static let lipEndRight = "flow-lip-end-right"
    /// The stone chute under a last-row mouth, dry and wet (batch 135).
    public static let spoutDry = "flow-spout-dry"
    public static let spoutWet = "flow-spout-wet"
    /// The board's stone edge, a 9-slice (batch 132).
    public static let edge = "flow-board-edge"
    /// Method B: one seamless lawn.
    public static let lawn = "flow-lawn"
    public static let spring = "flow-spring"
    public static let outlet = "flow-outlet"
    public static let wheel = "flow-wheel"
    public static let gate = "flow-gate"
    /// Seamless materials the code fills the carved channel and the water with.
    public static let channelBed = "flow-channel"
    public static let water = "flow-water"
    /// The painted scene behind the board (batch 124 `x-flow-backdrop`).
    public static let backdrop = "flow-backdrop"
    public static let maxVariants = 6

    /// The cut-out rocks (batch 135) all paint their own contact shade, so the code adds none.
    public static func rockCutHasPaintedShade(variant index: Int) -> Bool { true }

    public static func variantName(_ base: String, _ index: Int) -> String {
        index == 0 ? base : "\(base)-\(index + 1)"
    }
}

/// Picks which picture and orientation a bank cell wears, from the cell and
/// the board alone, so the same board always looks the same.
public struct FlowVariantPicker: Sendable {
    public let columns: Int
    public let rows: Int
    private let ordinals: [FlowCell: Int]

    public init(board: FlowBoard) {
        columns = board.columns
        rows = board.rows
        var counts: [FlowTileKind: Int] = [:]
        var map: [FlowCell: Int] = [:]
        for cell in board.allCells.sorted() {
            guard let tile = board[cell], tile.kind == .rock || tile.kind == .grass else { continue }
            map[cell] = counts[tile.kind, default: 0]
            counts[tile.kind, default: 0] += 1
        }
        ordinals = map
    }

    private func hash(_ cell: FlowCell, _ salt: Int) -> Int {
        var value = (cell.row &* 73856093) ^ (cell.column &* 19349663) ^ (salt &* 83492791)
        value = (value ^ (value >> 13)) &* 1274126177
        return (value ^ (value >> 16)) & 0x7FFF_FFFF
    }

    /// The variant index for a cell. Cells of one kind take consecutive
    /// variants in reading order from a start the board chooses, so no
    /// picture repeats on a board until the variants run out, and two
    /// neighbours in a row never match.
    public func variant(of cell: FlowCell, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let start = (columns &* 5 &+ rows &* 3) % count
        return ((ordinals[cell] ?? hash(cell, 1)) &+ start) % count
    }

    /// A quarter turn (0 to 3) for a grass cell, so a lawn picture does not
    /// repeat with its neighbour.
    public func quarterTurns(of cell: FlowCell) -> Int { hash(cell, 2) % 4 }

    /// Whether the picture is mirrored (rocks only mirror, so the light stays on top).
    public func mirrored(_ cell: FlowCell) -> Bool { hash(cell, 3) % 2 == 1 }
}
