import Foundation
import Testing

@testable import PofuGames

@Suite("Flow ground")
struct FlowGroundTests {
    private let board = FlowBoard(rows: ["S # . #", ". . # .", "└ ┘ . P"])!

    private func shipped(_ name: String) -> Bool {
        Bundle.module.url(forResource: name, withExtension: "png") != nil
    }

    /// A missing art file is a failure here, not a drawing in its place.
    @Test func everyPaintedPieceShips() {
        for name in FlowArtSlot.required { #expect(shipped(name), "\(name)") }
    }

    @Test func everyKindHasABlockAndTheTurnableOnesADial() {
        for kind in FlowTileKind.allCases {
            #expect(FlowArtSlot.required.contains(FlowArtSlot.blockName(of: kind)), "\(kind)")
            #expect((FlowArtSlot.dialName(of: kind) != nil) == kind.isTurnable, "\(kind)")
            if let bed = FlowArtSlot.bedName(of: kind) { #expect(FlowArtSlot.required.contains(bed), "\(kind)") }
        }
        // Only a piece with a channel has water; rock and grass have none.
        #expect(FlowArtSlot.bedName(of: .rock) == nil)
        #expect(FlowArtSlot.bedName(of: .grass) == nil)
        #expect(FlowArtSlot.bedName(of: .wheel) != nil)
    }

    /// The ingest tool's numbers are shipped and sane, and the plate lies inside the picture.
    @Test func theKitNumbersLoad() {
        let kit = FlowKit.shared
        #expect(kit.canvas > 0)
        #expect(kit.body > 0.9 && kit.body <= 1 && kit.disc > 0.9 && kit.disc <= 1)
        #expect(kit.plate.x > 0 && kit.plate.y > 0)
        #expect(kit.plate.x + kit.plate.width < 1 && kit.plate.y + kit.plate.height < 1)
    }

    @Test func flowersAreAnAccentOnGrassOnly() {
        let picker = FlowVariantPicker(board: board)
        let again = FlowVariantPicker(board: board)
        var flowered = 0
        for row in 0..<40 {
            for column in 0..<40 {
                let cell = FlowCell(row: row, column: column)
                #expect(picker.flowered(cell) == again.flowered(cell))
                guard picker.flowered(cell) else { continue }
                flowered += 1
                #expect(!picker.flowered(FlowCell(row: row, column: column + 1)))
                #expect(!picker.flowered(FlowCell(row: row + 1, column: column)))
            }
        }
        // About one in five seeds, fewer where neighbours would meet: an accent.
        #expect(flowered > 0 && flowered < 1600 / 5)
    }

    /// The board lies on the backdrop's plate, centred, in cells of 44 pt or more, with the side gutter kept clear of cells.
    @Test func theBoardLiesOnThePlate() {
        for width in [375.0, 402.0, 440.0] {
            let height = width * 874 / 402
            for (columns, rows) in [(3, 4), (5, 6), (4, 5)] {
                let layout = FlowLayout(size: CGSize(width: width, height: height), safeTop: 62, safeBottom: 34, columns: columns, rows: rows)
                #expect(layout.cell >= FlowLayout.minCell)
                // The board's origin is rounded to a point, so it may pass the plate by under one.
                #expect(layout.board.minX >= layout.plate.minX - 1 && layout.board.maxX <= layout.plate.maxX + 1, "\(columns)x\(rows) at \(width)")
                #expect(layout.board.minY >= layout.plate.minY - 1 && layout.board.maxY <= layout.plate.maxY + 1, "\(columns)x\(rows) at \(width)")
                #expect(abs(layout.board.midX - layout.plate.midX) <= 1)
                #expect(layout.board.minX >= FlowLayout.gutter)
                #expect(width - layout.board.maxX >= FlowLayout.gutter)
                #expect(layout.plate.minY >= 62 + FlowLayout.hudHeight)
                #expect(layout.plate.maxY <= height - 34 - FlowLayout.controlsHeight)
            }
        }
    }
}
