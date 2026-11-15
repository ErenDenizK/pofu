import Foundation
import Testing
@testable import PofuWorld

@Suite("Screen bands")
struct ScreenBandsTests {
    @Test func bandsMatchTheTableOnIPhone17() {
        let b = ScreenBands(width: 402, height: 874)
        #expect(b.topSafe == 0 ... 59)
        #expect(b.topRow == 59 ... 118)
        #expect(b.stage == 118 ... 628)
        #expect(b.midChrome == 628 ... 840)
        #expect(b.bottomSafe == 840 ... 874)
        #expect(b.corner == ScreenBox(minX: 314, minY: 766, maxX: 386, maxY: 840))
        #expect(b.cornerMirrored == ScreenBox(minX: 16, minY: 766, maxX: 88, maxY: 840))
        #expect(ScreenBands.reference == b)
        #expect(ScreenBands.defaultSafeTop == 59)
    }

    @Test func bandsKeepTheirHeightsOnASmallPhone() {
        // iPhone SE (3rd generation): 375 x 667, a 20 pt status bar.
        let small = ScreenBands(width: 375, height: 667, safeTop: 20)
        let big = ScreenBands.reference
        func h(_ r: ClosedRange<Double>) -> Double { r.upperBound - r.lowerBound }
        #expect(h(small.topRow) == h(big.topRow))
        #expect(h(small.midChrome) == h(big.midChrome))
        #expect(h(small.bottomSafe) == 34)
        #expect(small.corner.height == big.corner.height)
        #expect(small.topSafe.upperBound == 20, "safeTop comes in")
        #expect(small.bottomSafe.upperBound == 667, "the bottom bands hang from the bottom")
        #expect(small.midChrome.upperBound == 667 - 34)
        // Horizontal values scale by width.
        #expect(abs(small.corner.maxX - 386 * 375 / 402) < 1e-9)
        #expect(abs(small.widthScale - 375.0 / 402.0) < 1e-12)
    }
}
