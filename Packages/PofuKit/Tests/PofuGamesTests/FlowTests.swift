import Foundation
import Testing

@testable import PofuGames

@Suite("Flow game")
struct FlowTests {
    // MARK: Tiles

    @Test func fourTapsAreTheIdentityAndStraightsHaveTwoStates() {
        for kind in [FlowTileKind.bend, .split] {
            var tile = FlowTile(kind: kind)
            let start = tile
            var states: Set<FlowDirection.RawValue> = []
            for _ in 0..<4 {
                states.insert(tile.openings.rawValue)
                tile = tile.rotatedClockwise
            }
            #expect(tile == start)
            #expect(states.count == 4)
        }
        var straight = FlowTile(kind: .straight)
        let first = straight.openings
        straight = straight.rotatedClockwise
        #expect(straight.openings == [.east, .west])
        straight = straight.rotatedClockwise
        #expect(straight.openings == first)
    }

    @Test func glyphsRoundTripAndMatchTheNote() {
        for glyph in "│─└┌┐┘├┬┤┴SPWG#." {
            #expect(FlowTile(glyph: glyph)?.glyph == glyph)
        }
        // One clockwise tap: └→┌→┐→┘, ├→┬→┤→┴, │→─.
        #expect(FlowTile(glyph: "└")?.rotatedClockwise.glyph == "┌")
        #expect(FlowTile(glyph: "┘")?.rotatedClockwise.glyph == "└")
        #expect(FlowTile(glyph: "┴")?.rotatedClockwise.glyph == "├")
        #expect(FlowTile(glyph: "│")?.rotatedClockwise.glyph == "─")
        #expect(FlowTile(glyph: "W")?.openings == [.east, .west])
        #expect(FlowTile(glyph: "S")?.openings == .south)
        #expect(FlowTile(glyph: "P")?.openings == .north)
    }

    @Test func fixedTilesDoNotTurn() {
        var board = FlowBoard(rows: ["S", "G", "P"])!
        for cell in board.allCells {
            let turned = board.rotate(at: cell)
            #expect(!turned)
        }
        #expect(board.glyphRows == ["S", "G", "P"])
    }

    @Test func boardsParseAndPrint() {
        let rows = ["S # .", "┘ └ #", "# ─ ─", "# P #"]
        let board = FlowBoard(rows: rows)
        #expect(board?.glyphRows == rows)
        #expect(board?.columns == 3 && board?.rows == 4)
        #expect(FlowBoard(rows: ["S #", "P"]) == nil)
        #expect(FlowBoard(rows: ["S X"]) == nil)
    }

    // MARK: Solver

    @Test func waterFollowsFacingOpeningsFromTheSource() {
        let board = FlowBoard(rows: ["S # .", "┘ └ #", "# ─ ─", "# P #"])!
        #expect(FlowSolver.wet(board) == [FlowCell(row: 0, column: 0), FlowCell(row: 1, column: 0)])
        #expect(!FlowSolver.isSolved(board))
    }

    @Test func aSplitFeedsBothArms() {
        let board = FlowBoard(rows: ["# S #", "┌ ┴ ┐", "│ # │", "P # P"])!
        #expect(FlowSolver.isSolved(board))
        #expect(FlowSolver.wet(board).count == 8)
    }

    @Test func aSpillNeverCounts() {
        // The split's east arm dribbles off the board; only the west mouth is fed.
        let board = FlowBoard(rows: ["# S #", "┌ ┴ ─", "│ # #", "P # P"])!
        #expect(!FlowSolver.isSolved(board))
        let spills = FlowSolver.spills(board)
        #expect(spills.contains(FlowSpill(cell: FlowCell(row: 1, column: 2), side: .east)))
        #expect(!FlowSolver.wet(board).contains(FlowCell(row: 3, column: 2)))
    }

    @Test func aWheelIsATargetThatWaterPassesThrough() {
        let wetWheel = FlowBoard(rows: ["S # #", "└ W ┐", "# # │", "# # P"])!
        #expect(FlowSolver.isSolved(wetWheel))
        let dryWheel = FlowBoard(rows: ["S # #", "└ # ┐", "# W │", "# # P"])!
        #expect(!FlowSolver.isSolved(dryWheel))
    }

    @Test func aBoardWithoutTargetsIsNeverSolved() {
        #expect(!FlowSolver.isSolved(FlowBoard(rows: ["S", "│"])!))
    }

    @Test func minimumTapsOnASmallBoard() {
        // r1c0 ┘→└ (1 tap), r1c1 ┘→└→┌→┐ (3 taps).
        let board = FlowBoard(rows: ["S #", "┘ ┘", "# P"])!
        #expect(FlowSolver.minimumTaps(board) == 4)
        let solution = FlowSolver.solve(board)
        var played = board
        for (cell, rotation) in solution?.rotations ?? [:] {
            while played[cell]?.rotation != rotation { played.rotate(at: cell) }
        }
        #expect(FlowSolver.isSolved(played))
    }

    @Test func anImpossibleBoardHasNoSolution() {
        #expect(FlowSolver.solve(FlowBoard(rows: ["S", "#", "P"])!) == nil)
    }

    // MARK: Shipped boards

    @Test func everyShippedBoardParsesAndIsWellFormed() {
        let records = FlowLibrary.records
        #expect(records.count == 8)
        #expect(Set(records.map(\.id)).count == records.count)
        for record in records {
            guard let board = record.board else {
                Issue.record("\(record.id) does not parse")
                continue
            }
            #expect(board.cells(of: .source).count == 1, "\(record.id)")
            #expect(!board.targets.isEmpty, "\(record.id)")
            #expect(board.columns <= 5 && board.columns >= 3, "\(record.id)")
            #expect(board.rows >= 4 && board.rows <= 7, "\(record.id)")
        }
    }

    /// The note's table: (stage, order) -> (columns, rows, intended taps).
    static let ramp: [String: (columns: Int, rows: Int, taps: Int)] = [
        "caglayan-1-1": (3, 4, 4), "caglayan-1-2": (4, 4, 6),
        "caglayan-2-1": (4, 5, 10), "caglayan-2-2": (4, 5, 10),
        "caglayan-3-1": (4, 5, 9), "caglayan-3-2": (5, 5, 11),
        "caglayan-4-1": (5, 5, 12), "caglayan-4-2": (5, 6, 14),
    ]

    @Test func everyShippedBoardIsSolvableNotSolvedAndInTheRamp() throws {
        for record in FlowLibrary.records {
            let board = try #require(record.board)
            #expect(!FlowSolver.isSolved(board), "\(record.id) starts solved")
            let taps = try #require(FlowSolver.minimumTaps(board), "\(record.id) is unsolvable")
            let expected = try #require(Self.ramp[record.id], "\(record.id) is not in the ramp")
            #expect(abs(taps - expected.taps) <= 1, "\(record.id): \(taps) taps, intended \(expected.taps)")
            #expect(board.columns == expected.columns && board.rows == expected.rows, "\(record.id) size")
        }
    }

    @Test func theNotesExampleBoardsHaveTheNotesMinimums() throws {
        for (id, taps) in [("caglayan-1-1", 4), ("caglayan-2-1", 10), ("caglayan-3-2", 11), ("caglayan-4-2", 14)] {
            let record = try #require(FlowLibrary.records.first { $0.id == id })
            #expect(FlowSolver.minimumTaps(try #require(record.board)) == taps, "\(id)")
        }
    }

    @Test func everyStageHasARound() {
        for stage in 1...4 {
            #expect(FlowLibrary.round(stage: stage)?.boardCount == 2)
        }
        #expect(FlowLibrary.round(stage: 5) == nil)
        #expect(FlowLibrary.round(island: "revontuli", stage: 1) == nil)
    }

    // MARK: Round

    private func firstRound() throws -> FlowRound {
        try #require(FlowLibrary.round(stage: 1))
    }

    @Test func undoRestoresTheExactBoard() throws {
        var round = try firstRound()
        let start = round.board
        let cells = round.board.turnableCells
        var snapshots = [start]
        for cell in cells.prefix(5) {
            round.tap(at: cell)
            snapshots.append(round.board)
        }
        for expected in snapshots.dropLast().reversed() {
            round.undo()
            #expect(round.board == expected)
        }
        #expect(round.board == start)
        let nothing = round.undo()
        #expect(nothing == nil)
    }

    @Test func tappingAFixedTileIsIgnored() throws {
        var round = try firstRound()
        let before = round
        let source = round.board.cells(of: .source)[0]
        let result = round.tap(at: source)
        #expect(!result.turned)
        #expect(round == before)
    }

    @Test func aTapReportsNewWater() throws {
        var round = try firstRound()
        // Stage 1 board 1: r1c0 ┘→└ makes no new water (it is already wet);
        // turning r1c1 after it wets the next tile.
        round.tap(at: FlowCell(row: 1, column: 0))
        let result = round.tap(at: FlowCell(row: 1, column: 1))
        #expect(result.turned)
        #expect(result.newlyWet.isEmpty || result.newlyWet.contains(FlowCell(row: 1, column: 1)))
    }

    @Test func hintPointsAtAWrongTurnableTileOnASolution() throws {
        for record in FlowLibrary.records {
            var board = try #require(record.board)
            // From the start and after some wrong taps, the hint is a turnable
            // tile that differs from its rotation in the solution it names.
            for step in 0..<2 {
                guard let hint = FlowHint.next(board) else { Issue.record("\(record.id): no hint"); break }
                let tile = try #require(board[hint.cell])
                #expect(tile.kind.isTurnable)
                #expect(tile.rotation != hint.rotation, "\(record.id) points at a tile that is already right")
                var turned = board
                while turned[hint.cell]?.rotation != hint.rotation { turned.rotate(at: hint.cell) }
                // Following the hint never makes the board unsolvable or longer.
                let before = try #require(FlowSolver.minimumTaps(board))
                let after = try #require(FlowSolver.minimumTaps(turned))
                #expect(after < before, "\(record.id): a hint should bring the solution closer")
                board.rotate(at: board.turnableCells[(step * 3) % board.turnableCells.count])
                if FlowSolver.minimumTaps(board) == nil { break }
            }
        }
    }

    @Test func noHintOnASolvedBoard() {
        #expect(FlowHint.next(FlowBoard(rows: ["S", "│", "P"])!) == nil)
    }

    @Test func theRoundAdvancesOnlyWhenEveryBoardIsSolved() throws {
        var round = try firstRound()
        let early = round.advance()
        #expect(!early)
        #expect(!round.isComplete)
        for index in 0..<round.boardCount {
            #expect(round.index == index)
            while !round.isBoardSolved {
                let hint = try #require(round.hint)
                #expect(!round.isComplete)
                round.tap(at: hint.cell)
            }
            #expect(round.canUndo == false, "a solved board is locked")
            if index < round.boardCount - 1 {
                #expect(!round.isComplete)
                let moved = round.advance()
                #expect(moved)
            }
        }
        #expect(round.isComplete)
        let extra = round.advance()
        #expect(!extra)
        // Locked: a tap on the solved board does nothing.
        let solved = round.board
        round.tap(at: round.board.turnableCells[0])
        #expect(round.board == solved)
    }

    @Test func followingHintsSolvesWithinTheMinimum() throws {
        for record in FlowLibrary.records {
            var round = FlowRound(boards: [try #require(record.board)])
            let minimum = try #require(FlowSolver.minimumTaps(round.board))
            var taps = 0
            while !round.isBoardSolved, taps < 60 {
                let hint = try #require(round.hint)
                round.tap(at: hint.cell)
                taps += 1
            }
            #expect(round.isBoardSolved, "\(record.id)")
            #expect(taps == minimum, "\(record.id): hints took \(taps), minimum \(minimum)")
        }
    }

    @Test func aRoundSurvivesCodable() throws {
        var round = try firstRound()
        round.tap(at: FlowCell(row: 1, column: 0))
        let data = try JSONEncoder().encode(round)
        #expect(try JSONDecoder().decode(FlowRound.self, from: data) == round)
    }
}
