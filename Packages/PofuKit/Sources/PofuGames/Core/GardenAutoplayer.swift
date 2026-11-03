/// A plain greedy player: for tests (whole rounds must end, yields must
/// land in the expected band), screenshots and balancing. It prefers
/// blooms, then snug placements, and avoids leaving holes. Not a hint
/// system: Pofu never shows "the best move".
public enum GardenAutoplayer {
    public struct Move: Sendable, Equatable {
        public let slot: Int
        public let origin: GardenCell
    }

    public static func bestMove(in round: GardenRound) -> Move? {
        var best: (move: Move, score: Int)?
        for slot in round.tray.indices {
            guard let shape = round.piece(in: slot) else { continue }
            for origin in round.board.origins(for: shape) {
                let score = Self.score(shape, at: origin, on: round.board)
                if score > (best?.score ?? .min) {
                    best = (Move(slot: slot, origin: origin), score)
                }
            }
        }
        return best?.move
    }

    /// The first move that blooms at least one line, if any.
    public static func bloomingMove(in round: GardenRound) -> Move? {
        for slot in round.tray.indices {
            guard let shape = round.piece(in: slot) else { continue }
            for origin in round.board.origins(for: shape) where !round.preview(slot: slot, at: origin).isEmpty {
                return Move(slot: slot, origin: origin)
            }
        }
        return nil
    }

    static func score(_ shape: PieceShape, at origin: GardenCell, on board: GardenBoard) -> Int {
        var after = board
        guard let placement = after.place(shape, at: origin) else { return .min }
        var contact = 0
        for cell in GardenBoard.cells(in: placement.planted) {
            for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                let neighbour = GardenCell(row: cell.row + dr, column: cell.column + dc)
                if !GardenBoard.contains(neighbour) || board.isPlanted(neighbour) { contact += 1 }
            }
        }
        return placement.cleared.count * 100 + contact * 3 - (after.holes - board.holes) * 12
    }
}
