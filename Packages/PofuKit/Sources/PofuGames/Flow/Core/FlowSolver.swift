/// A spill: an opening of a wet tile that faces nothing that takes water
/// (the board's edge, a rock, a closed side). A small harmless dribble.
public struct FlowSpill: Hashable, Sendable {
    public let cell: FlowCell
    public let side: FlowDirection
}

/// One cheapest answer: the tiles to turn, with the rotation each must end
/// at, and the taps that costs.
public struct FlowSolution: Sendable, Equatable {
    public let taps: Int
    public let rotations: [FlowCell: Int]
}

public enum FlowSolver {
    /// Breadth-first from every source through each pair of facing openings.
    /// Water runs both ways along a channel.
    public static func wet(_ board: FlowBoard) -> Set<FlowCell> {
        var seen = Set(board.cells(of: .source))
        var queue = Array(seen)
        var head = 0
        while head < queue.count {
            let cell = queue[head]
            head += 1
            guard let tile = board[cell] else { continue }
            for side in FlowDirection.sides where tile.openings.contains(side) {
                let next = cell.neighbour(side)
                guard !seen.contains(next), let other = board[next], other.openings.contains(side.opposite) else { continue }
                seen.insert(next)
                queue.append(next)
            }
        }
        return seen
    }

    /// The wet tiles with how far each is from the spring (0 for the source)
    /// and the side the water came in by (nil for the source), so a scene
    /// can pour along the channel from where a new connection starts.
    public static func flow(_ board: FlowBoard) -> [FlowCell: (depth: Int, entered: FlowDirection?)] {
        var result: [FlowCell: (depth: Int, entered: FlowDirection?)] = [:]
        var queue = board.cells(of: .source)
        for cell in queue { result[cell] = (0, nil) }
        var head = 0
        while head < queue.count {
            let cell = queue[head]
            head += 1
            guard let tile = board[cell], let depth = result[cell]?.depth else { continue }
            for side in FlowDirection.sides where tile.openings.contains(side) {
                let next = cell.neighbour(side)
                guard result[next] == nil, let other = board[next], other.openings.contains(side.opposite) else { continue }
                result[next] = (depth + 1, side.opposite)
                queue.append(next)
            }
        }
        return result
    }

    public static func isSolved(_ board: FlowBoard) -> Bool {
        isSolved(board, wet: wet(board))
    }

    public static func isSolved(_ board: FlowBoard, wet: Set<FlowCell>) -> Bool {
        let targets = board.targets
        return !targets.isEmpty && targets.allSatisfy(wet.contains)
    }

    public static func spills(_ board: FlowBoard) -> [FlowSpill] {
        spills(board, wet: wet(board))
    }

    public static func spills(_ board: FlowBoard, wet: Set<FlowCell>) -> [FlowSpill] {
        var result: [FlowSpill] = []
        for cell in wet.sorted() {
            guard let tile = board[cell] else { continue }
            for side in FlowDirection.sides where tile.openings.contains(side) {
                if board[cell.neighbour(side)]?.openings.contains(side.opposite) != true {
                    result.append(FlowSpill(cell: cell, side: side))
                }
            }
        }
        return result
    }

    /// The fewest taps that solve `board`, with the rotations that do it;
    /// nil if unsolvable. Grows a wet tree outward from the source, trying
    /// each rotation of a turnable tile that opens toward the frontier,
    /// with branch-and-bound on the tap count. Boards of at most 35 cells
    /// and 16 turnable tiles solve in a blink.
    public static func solve(_ board: FlowBoard) -> FlowSolution? {
        var search = Search(board: board)
        return search.run()
    }

    public static func minimumTaps(_ board: FlowBoard) -> Int? {
        solve(board)?.taps
    }

    private struct Search {
        let board: FlowBoard
        var best: FlowSolution?

        init(board: FlowBoard) { self.board = board }

        mutating func run() -> FlowSolution? {
            guard let source = board.cells(of: .source).first else { return nil }
            explore(assigned: [:], cost: 0, frontier: [source], visited: [source])
            return best
        }

        private func current(_ cell: FlowCell, _ assigned: [FlowCell: Int]) -> FlowTile {
            let tile = board[cell]!
            if let rotation = assigned[cell] { return FlowTile(kind: tile.kind, rotation: rotation) }
            return tile
        }

        private func isSolved(_ assigned: [FlowCell: Int]) -> Bool {
            var copy = board
            for (cell, rotation) in assigned { copy.set(FlowTile(kind: board[cell]!.kind, rotation: rotation), at: cell) }
            return FlowSolver.isSolved(copy)
        }

        private mutating func explore(assigned: [FlowCell: Int], cost: Int, frontier: [FlowCell], visited: Set<FlowCell>) {
            if let best, cost >= best.taps { return }
            if isSolved(assigned) {
                best = FlowSolution(taps: cost, rotations: assigned)
                return
            }
            guard let cell = frontier.first else { return }
            let sides = FlowDirection.sides.filter { current(cell, assigned).openings.contains($0) }
            expand(cell: cell, sides: sides[...], rest: Array(frontier.dropFirst()), assigned: assigned, cost: cost, visited: visited)
        }

        private mutating func expand(
            cell: FlowCell, sides: ArraySlice<FlowDirection>, rest: [FlowCell],
            assigned: [FlowCell: Int], cost: Int, visited: Set<FlowCell>
        ) {
            guard let side = sides.first else {
                explore(assigned: assigned, cost: cost, frontier: rest, visited: visited)
                return
            }
            let more = sides.dropFirst()
            let next = cell.neighbour(side)
            guard let tile = board[next], !visited.contains(next) else {
                expand(cell: cell, sides: more, rest: rest, assigned: assigned, cost: cost, visited: visited)
                return
            }
            if tile.kind.isTurnable {
                // Leave it alone on this edge (another path may use it)...
                expand(cell: cell, sides: more, rest: rest, assigned: assigned, cost: cost, visited: visited)
                // ...or turn it so it opens toward the water.
                for state in 0..<tile.kind.stateCount {
                    let candidate = FlowTile(kind: tile.kind, rotation: state)
                    guard candidate.openings.contains(side.opposite) else { continue }
                    var next2 = assigned
                    next2[next] = state
                    expand(
                        cell: cell, sides: more, rest: rest + [next], assigned: next2,
                        cost: cost + tile.taps(to: candidate), visited: visited.union([next])
                    )
                }
            } else if tile.openings.contains(side.opposite) {
                expand(cell: cell, sides: more, rest: rest + [next], assigned: assigned, cost: cost, visited: visited.union([next]))
            } else {
                expand(cell: cell, sides: more, rest: rest, assigned: assigned, cost: cost, visited: visited)
            }
        }
    }
}

public struct FlowHint: Equatable, Sendable {
    /// The tile to turn.
    public let cell: FlowCell
    /// The rotation that is right for it (the ghost's turn).
    public let rotation: Int

    /// The turnable tile nearest the wet frontier whose rotation differs
    /// from the nearest solution; nil when solved or unsolvable. Never
    /// changes the board.
    public static func next(_ board: FlowBoard, excluding skipped: Set<FlowCell> = []) -> FlowHint? {
        guard let solution = FlowSolver.solve(board), solution.taps > 0 else { return nil }
        let wet = FlowSolver.wet(board)
        var wrong = solution.rotations.filter { cell, rotation in board[cell]?.rotation != rotation }
        // "Another 20 s, another tile": skip the ones already pointed at,
        // unless nothing else is left.
        let fresh = wrong.filter { !skipped.contains($0.key) }
        if !fresh.isEmpty { wrong = fresh }
        func distance(_ cell: FlowCell) -> Int {
            wet.map { abs($0.row - cell.row) + abs($0.column - cell.column) }.min() ?? 0
        }
        guard let cell = wrong.keys.min(by: { (distance($0), $0) < (distance($1), $1) }) else { return nil }
        return FlowHint(cell: cell, rotation: wrong[cell] ?? 0)
    }
}
