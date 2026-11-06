import Foundation
import PofuDesignSystem
import Testing
@testable import PofuWorld

@Suite("The island's resist seals")
struct ResistSealsTests {
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func atRestEverySealIsThereAndNothingRuns() {
        let tally = ResistSealTally(total: 5)
        #expect(tally.shown == 5)
        #expect(!tally.isAnimating(at: start))
        for index in 0..<5 { #expect(tally.press(of: index, at: start) == 1) }
    }

    @Test func onlyTheNewSealsAnimateTheEarlierOnesAreAlreadyThere() {
        let tally = ResistSealTally(total: 5, fresh: 2, start: start)
        let early = start.addingTimeInterval(0.35)
        for index in 0..<3 { #expect(tally.press(of: index, at: early) == 1, "seal \(index) was there before") }
        #expect(tally.press(of: 3, at: early) > 0 && tally.press(of: 3, at: early) < 1)
        #expect(tally.press(of: 4, at: early) == 0, "the second new seal waits its 0.18 s")
        #expect(tally.press(of: 4, at: start.addingTimeInterval(2)) == 1)
        #expect(tally.isAnimating(at: start.addingTimeInterval(1)))
        #expect(!tally.isAnimating(at: start.addingTimeInterval(2.1)))
    }

    @Test func theIslandShowsEightAndTheLastCarriesPlusN() {
        #expect(ResistSealTally(total: 8).overflow == 0)
        let many = ResistSealTally(total: 11)
        #expect(many.shown == 8)
        #expect(many.overflow == 3)
        #expect(ResistSealTally(total: 0).shown == 0, "a day with no resists draws nothing")
        #expect(ResistSealTally(total: 3, fresh: 9, start: start).press(of: 0, at: start) == 0, "all three are new")
    }

    @Test func slotsHangUnderPofuBelowTheDoorsAndNeverOverlap() {
        for index in 0..<DoorStamp.maxSeals {
            let p = ResistSealLayout.point(of: index)
            #expect(p.y >= 110 && p.y <= 150, "on the earth band under the doors' feet")
            #expect(abs(p.x - 22) <= 90, "centred under Pofu, on screen")
        }
        for a in 0..<DoorStamp.maxSeals {
            for b in (a + 1)..<DoorStamp.maxSeals {
                let pa = ResistSealLayout.point(of: a), pb = ResistSealLayout.point(of: b)
                #expect(hypot(pa.x - pb.x, pa.y - pb.y) >= 18, "\(a) and \(b)")
            }
        }
    }

    @Test func aSealIsTwentyFourToTwentyEightPoints() {
        for scale in [0.3, 0.9, 1.0, 3.0] {
            let side = ResistSealLayout.side(scale: scale)
            #expect(side >= 24 && side <= 28)
        }
    }
}
