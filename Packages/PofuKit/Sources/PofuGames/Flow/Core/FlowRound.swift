import Foundation

/// What a tap did, for the scene to animate.
public struct FlowTapResult: Equatable, Sendable {
    /// The tile turned (false for a fixed tile, a locked board, off-board).
    public let turned: Bool
    /// Tiles that are wet now and were dry before the tap.
    public let newlyWet: [FlowCell]
    /// Tiles that were wet before and are dry now.
    public let newlyDry: [FlowCell]
    public let solved: Bool

    static let ignored = FlowTapResult(turned: false, newlyWet: [], newlyDry: [], solved: false)
}

/// A round of one to three small boards played back to back. A value type,
/// like `GardenRound`; `Codable` so a half-played round can be saved and
/// resumed the same day or a later one. No fail state, no clock, no score:
/// the only ending is every board solved.
public struct FlowRound: Hashable, Sendable, Codable {
    public private(set) var boards: [FlowBoard]
    public private(set) var index: Int
    /// The board being played, as it stands now.
    public private(set) var board: FlowBoard
    /// Every tap on the current board, oldest first. Undo pops it; there is
    /// no reset button (undo to the start is the reset).
    public private(set) var taps: [FlowCell]

    /// - Precondition: `boards` is not empty.
    public init(boards: [FlowBoard]) {
        precondition(!boards.isEmpty, "a flow round needs a board")
        self.boards = boards
        index = 0
        board = boards[0]
        taps = []
    }

    public var boardCount: Int { boards.count }
    public var wet: Set<FlowCell> { FlowSolver.wet(board) }
    public var isBoardSolved: Bool { FlowSolver.isSolved(board) }
    public var canUndo: Bool { !taps.isEmpty && !isBoardSolved }
    public var isLastBoard: Bool { index == boards.count - 1 }

    /// The round is done only when every board is solved: the last board
    /// is the current one and it is solved.
    public var isComplete: Bool { isLastBoard && isBoardSolved }

    public var targetsWet: Int { board.targets.filter(wet.contains).count }
    public var targetCount: Int { board.targets.count }

    /// Turns the tile at `cell`. A solved board is locked.
    @discardableResult
    public mutating func tap(at cell: FlowCell) -> FlowTapResult {
        guard !isBoardSolved else { return .ignored }
        let before = wet
        guard board.rotate(at: cell) else { return .ignored }
        taps.append(cell)
        let after = wet
        return FlowTapResult(
            turned: true,
            newlyWet: after.subtracting(before).sorted(),
            newlyDry: before.subtracting(after).sorted(),
            solved: FlowSolver.isSolved(board, wet: after)
        )
    }

    /// Steps back the last tap; nil when there is nothing to undo or the
    /// board is solved (locked). Returns the cell that turned back.
    @discardableResult
    public mutating func undo() -> FlowCell? {
        guard canUndo, let cell = taps.popLast(), let tile = board[cell] else { return nil }
        // Three more quarter turns undo one (a straight toggles back).
        board.set(tile.rotated(by: tile.kind.stateCount - 1), at: cell)
        return cell
    }

    /// Moves on to the next board after one is solved; false otherwise.
    @discardableResult
    public mutating func advance() -> Bool {
        guard isBoardSolved, !isLastBoard else { return false }
        index += 1
        board = boards[index]
        taps = []
        return true
    }

    /// The tile Damla points at after 20 s idle.
    public var hint: FlowHint? { isBoardSolved ? nil : FlowHint.next(board) }

    /// Seconds without a tap before a hint (design note §2).
    public static let hintDelay: TimeInterval = 20
}
