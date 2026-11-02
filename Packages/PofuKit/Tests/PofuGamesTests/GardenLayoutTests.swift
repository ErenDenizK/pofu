import CoreGraphics
import Testing
@testable import PofuGames

@Suite("Garden layout")
struct GardenLayoutTests {
    /// iPhone 17 (402 × 874 pt), an SE-class phone, and a Pro Max.
    let phones: [(CGSize, CGFloat, CGFloat)] = [
        (CGSize(width: 402, height: 874), 62, 34),
        (CGSize(width: 375, height: 667), 20, 0),
        (CGSize(width: 440, height: 956), 62, 34),
    ]

    @Test func theIPhone17GetsFortyOnePointCells() {
        let layout = GardenLayout(size: CGSize(width: 402, height: 874), safeTop: 62, safeBottom: 34)
        #expect(layout.cell == 41)
        #expect(layout.grid.width == 328)
    }

    @Test func nothingOverlapsOnAnyPhone() {
        for (size, top, bottom) in phones {
            let layout = GardenLayout(size: size, safeTop: top, safeBottom: bottom)
            let hudBottom = size.height - top - GardenLayout.hudHeight
            #expect(layout.bed.minX >= GardenLayout.sideGutter - 0.5, "\(size)")
            #expect(layout.bed.maxX <= size.width - GardenLayout.sideGutter + 0.5, "\(size)")
            #expect(layout.bed.minY > layout.tray.maxY, "\(size)")
            #expect(layout.pofu.y + layout.pofuHeight <= hudBottom, "\(size)")
            #expect(layout.tray.minY >= bottom, "\(size)")
            #expect(layout.cell <= GardenLayout.maximumCell)
        }
    }

    @Test func cellCentresAndFractionalOriginsAgree() throws {
        let layout = GardenLayout(size: CGSize(width: 402, height: 874), safeTop: 62, safeBottom: 34)
        let ell = try #require(PieceCatalog.shapes(of: .ell4).first)
        for origin in [GardenCell(row: 0, column: 0), GardenCell(row: 3, column: 5), GardenCell(row: 5, column: 6)] {
            let center = layout.center(of: ell, at: origin)
            let fractional = layout.fractionalOrigin(of: ell, centeredAt: center)
            #expect(abs(fractional.row - Double(origin.row)) < 1e-9)
            #expect(abs(fractional.column - Double(origin.column)) < 1e-9)
        }
        let topLeft = layout.center(of: GardenCell(row: 0, column: 0))
        #expect(topLeft.x == layout.grid.minX + 20.5)
        #expect(topLeft.y == layout.grid.maxY - 20.5)
    }

    @Test func traySlotsSplitTheTrayInThirds() {
        let layout = GardenLayout(size: CGSize(width: 402, height: 874), safeTop: 62, safeBottom: 34)
        #expect(layout.slot(at: CGPoint(x: layout.tray.minX + 5, y: layout.tray.midY)) == 0)
        #expect(layout.slot(at: CGPoint(x: layout.tray.midX, y: layout.tray.maxY + 20)) == 1, "generous above")
        #expect(layout.slot(at: CGPoint(x: layout.tray.maxX - 5, y: layout.tray.midY)) == 2)
        #expect(layout.slot(at: CGPoint(x: layout.tray.midX, y: layout.bed.midY)) == nil)
    }
}
