import Testing
@testable import PofuGames

@Suite("Garden board")
struct GardenBoardTests {
    private func shape(_ id: String) throws -> PieceShape {
        try #require(PieceCatalog.shape(id: id), "no shape \(id)")
    }

    @Test func aDrawnBoardRoundTrips() {
        let rows = [
            "#.......",
            ".#......",
            "........",
            "........",
            "........",
            "........",
            "........",
            "#######.",
        ]
        let board = GardenBoard(rows: rows)
        #expect(board.description == rows.joined(separator: "\n"))
        #expect(board.plantedCount == 9)
        #expect(board.isPlanted(GardenCell(row: 1, column: 1)))
        #expect(!board.isPlanted(GardenCell(row: 7, column: 7)))
        #expect(!board.isPlanted(GardenCell(row: 8, column: 0)))
    }

    @Test func aPieceFitsOnlyInsideTheBedAndOnSoil() throws {
        let line4 = try #require(PieceCatalog.shapes(of: .line4).first { $0.width == 4 })
        let board = GardenBoard(rows: ["...#...."])
        #expect(board.canPlace(line4, at: GardenCell(row: 1, column: 4)))
        #expect(!board.canPlace(line4, at: GardenCell(row: 1, column: 5)), "past the right edge")
        #expect(!board.canPlace(line4, at: GardenCell(row: 0, column: 0)), "over a sprout")
        #expect(!board.canPlace(line4, at: GardenCell(row: -1, column: 0)))
        #expect(board.canPlace(line4, at: GardenCell(row: 7, column: 4)))
    }

    @Test func placingFillsAndClearsARow() throws {
        let pair = try #require(PieceCatalog.shapes(of: .pair).first { $0.width == 2 })
        var board = GardenBoard(rows: ["######.."])
        let placementResult = board.place(pair, at: GardenCell(row: 0, column: 6))
        let placement = try #require(placementResult)
        #expect(placement.cleared == LineSet(rows: [0], columns: []))
        #expect(board.isEmpty)
    }

    @Test func aRowAndAColumnClearTogetherAndTheCrossingCountsOnce() throws {
        let single = try shape("single.0")
        var board = GardenBoard(rows: [
            "#######.",
            ".......#",
            ".......#",
            ".......#",
            ".......#",
            ".......#",
            ".......#",
            ".......#",
        ])
        let placementResult = board.place(single, at: GardenCell(row: 0, column: 7))
        let placement = try #require(placementResult)
        #expect(placement.cleared.rows == [0])
        #expect(placement.cleared.columns == [7])
        #expect(placement.cleared.count == 2)
        #expect(placement.cleared.cells.count == 15)
        #expect(board.isEmpty)
    }

    @Test func aFailedPlacementChangesNothing() throws {
        let square = try shape("square2.0")
        var board = GardenBoard(rows: ["#......."])
        let before = board
        #expect(board.place(square, at: GardenCell(row: 0, column: 0)) == nil)
        #expect(board.place(square, at: GardenCell(row: 7, column: 7)) == nil)
        #expect(board == before)
    }

    @Test func linesPreviewWithoutPlanting() {
        let board = GardenBoard(rows: ["#######."])
        let lines = board.lines(with: GardenBoard.bit(GardenCell(row: 0, column: 7)))
        #expect(lines.rows == [0])
        #expect(board.plantedCount == 7)
    }

    @Test func snapPrefersTheRoundedCellAndForgivesNearMisses() throws {
        let square = try shape("square2.0")
        let board = GardenBoard(rows: ["", "", "", "...#...."])
        // Rounded fits: take it.
        #expect(board.snap(square, row: 0.3, column: 0.4) == GardenCell(row: 0, column: 0))
        // Rounded is blocked by the sprout at (3,3): the nearest fit wins.
        #expect(board.snap(square, row: 1.6, column: 2.0) == GardenCell(row: 1, column: 2))
        // Blocked, and every fit is more than the tolerance away: nothing.
        #expect(board.snap(square, row: 2.6, column: 2.4) == nil)
        // Hanging off the right edge by less than a cell: pulled back in.
        #expect(board.snap(square, row: 0, column: 6.7) == GardenCell(row: 0, column: 6))
        // Far off the bed: nothing.
        #expect(board.snap(square, row: 0, column: 9.5) == nil)
    }

    @Test func holesAreEnclosedEmptyCells() {
        let board = GardenBoard(rows: [
            ".#......",
            "#.#.....",
            ".#......",
        ])
        // (0,0) is enclosed by the edges and two sprouts; (1,1) by four.
        #expect(board.holes == 2)
    }
}

@Suite("Piece catalog")
struct PieceCatalogTests {
    @Test func everyFamilyHasItsDistinctOrientations() {
        let counts = Dictionary(uniqueKeysWithValues: PieceFamily.allCases.map { ($0, PieceCatalog.shapes(of: $0).count) })
        #expect(counts[.single] == 1)
        #expect(counts[.pair] == 2)
        #expect(counts[.line5] == 2)
        #expect(counts[.corner3] == 4)
        #expect(counts[.square2] == 1)
        #expect(counts[.square3] == 1)
        #expect(counts[.ell4] == 8)
        #expect(counts[.tee4] == 4)
        #expect(counts[.skew4] == 4)
        #expect(counts[.rect6] == 2)
        #expect(counts[.corner5] == 4)
    }

    @Test func shapesAreNormalisedAndUnique() {
        let masks = PieceCatalog.all.map(\.mask)
        #expect(Set(masks).count == masks.count)
        #expect(Set(PieceCatalog.all.map(\.id)).count == PieceCatalog.all.count)
        for shape in PieceCatalog.all {
            #expect(shape.cells.map(\.row).min() == 0)
            #expect(shape.cells.map(\.column).min() == 0)
            #expect(shape.mask.nonzeroBitCount == shape.count)
            #expect(shape.width <= 5 && shape.height <= 5)
        }
    }
}
