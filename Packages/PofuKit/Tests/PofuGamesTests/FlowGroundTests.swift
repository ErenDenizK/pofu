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
}
