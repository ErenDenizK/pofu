import Foundation
import Testing

@testable import PofuGames

@Suite("Flow ground")
struct FlowGroundTests {
    private let board = FlowBoard(rows: ["S # . #", ". . # .", "└ ┘ . P"])!

    @Test func rocksOfOneBoardTakeDistinctVariants() {
        let picker = FlowVariantPicker(board: board)
        let rocks = board.allCells.filter { board[$0]?.kind == .rock }
        #expect(rocks.count == 3)
        let used = Set(rocks.map { picker.variant(of: $0, count: 4) })
        #expect(used.count == rocks.count)
    }

    @Test func variantsAreStableAndInRange() {
        let a = FlowVariantPicker(board: board)
        let b = FlowVariantPicker(board: board)
        for cell in board.allCells {
            #expect(a.variant(of: cell, count: 3) == b.variant(of: cell, count: 3))
            #expect((0..<3).contains(a.variant(of: cell, count: 3)))
            #expect((0..<4).contains(a.quarterTurns(of: cell)))
        }
        #expect(a.variant(of: FlowCell(row: 0, column: 0), count: 1) == 0)
    }

    @Test func variantNamesFollowTheSlotConvention() {
        #expect(FlowArtSlot.variantName("flow-rock", 0) == "flow-rock")
        #expect(FlowArtSlot.variantName("flow-rock", 2) == "flow-rock-3")
    }

    private func shipped(_ name: String) -> Bool {
        Bundle.module.url(forResource: name, withExtension: "png") != nil
    }

    /// Batch 135 ships four cut-out rocks, `flow-rock-cut` and `-2` to `-4`, and no fifth.
    @Test func fourCutOutRocksShip() {
        for index in 0..<4 { #expect(shipped(FlowArtSlot.variantName(FlowArtSlot.rockCut, index))) }
        #expect(!shipped(FlowArtSlot.variantName(FlowArtSlot.rockCut, 4)))
    }

    /// All four rocks paint their own contact shade; the code adds none.
    @Test func everyRockCarriesItsOwnShade() {
        #expect((0..<4).allSatisfy { FlowArtSlot.rockCutHasPaintedShade(variant: $0) })
    }

    /// The kit v2 pieces ship: lip (two ends, run, spillway), spout (dry, wet) and the board edge.
    @Test func theKitV2ArtShips() {
        for name in [FlowArtSlot.lipEndLeft, FlowArtSlot.lipRun, FlowArtSlot.lipSpill, FlowArtSlot.lipEndRight, FlowArtSlot.spoutDry, FlowArtSlot.spoutWet, FlowArtSlot.edge] {
            #expect(shipped(name), "\(name)")
        }
    }

    @Test func theLipRectHoldsAndTheEdgeKeepsTheGutter() {
        for width in [375.0, 402.0, 440.0] {
            let layout = FlowLayout(size: CGSize(width: width, height: 874), safeTop: 62, safeBottom: 34, columns: 5, rows: 4)
            // The drawn fallback lip's rect sits above the board, overlapping it by 6 pt at most, and is wider than tall.
            #expect(layout.lip.maxY == layout.board.minY + 6)
            #expect(layout.lip.height == FlowLayout.lipHeight + 6)
            #expect(layout.lip.width / layout.lip.height > 6)
            #expect(layout.lip.minY >= 62 + FlowLayout.hudHeight)
            // The stone edge reaches as far as the pool did, so the side gutter holds.
            #expect(layout.edge.minX >= FlowLayout.gutter)
            #expect(width - layout.edge.maxX >= FlowLayout.gutter)
        }
    }
}
