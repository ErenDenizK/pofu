import Testing
@testable import PofuWorld

@Suite struct SkyTilingTests {
    @Test(arguments: [1.0, 2.0, 3.0])
    func copiesMeetExactlyAtAnyShift(scale: Double) {
        for shift in stride(from: -400.0, through: 400.0, by: 13.37) {
            let spans = SkyTiling.spans(left: 22.3, width: 777.77, shift: shift, pixelsPerPoint: scale)
            #expect(spans.count == 3)
            for i in 0..<2 {
                // The right edge of one copy is the left edge of the next: no gap, no overlap.
                #expect(spans[i].maxX == spans[i + 1].x)
            }
            for span in spans {
                #expect((span.x * scale).rounded() == span.x * scale)
                #expect((span.maxX * scale).rounded() == span.maxX * scale)
                #expect(abs(span.width - 777.77) <= 1 / scale)
            }
        }
    }
}

@Suite struct SkyTilingManyCopiesTests {
    @Test func narrowTileCopiesMeetToo() {
        let spans = SkyTiling.spans(left: -50.2, width: 91.4, shift: 17.3, pixelsPerPoint: 3, copies: -2...9)
        #expect(spans.count == 12)
        for i in 0..<(spans.count - 1) { #expect(spans[i].maxX == spans[i + 1].x) }
    }
}
