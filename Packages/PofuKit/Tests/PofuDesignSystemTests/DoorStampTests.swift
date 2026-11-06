import Foundation
import Testing
import PofuDesignSystem

@Suite("The payoff at the door")
struct DoorStampTests {
    @Test func threeSealsStampOneByOneEvery180Milliseconds() {
        let stamp = DoorStamp(resists: 3)
        #expect(stamp.sealCount == 3)
        #expect(abs(stamp.sealStart(of: 1) - stamp.sealStart(of: 0) - 0.18) < 1e-9)
        #expect(abs(stamp.sealStart(of: 2) - stamp.sealStart(of: 1) - 0.18) < 1e-9)
        #expect(stamp.sealProgress(of: 0, at: 0.2) == 0)
        #expect(stamp.sealProgress(of: 0, at: stamp.sealStart(of: 0) + 0.09) > 0)
        #expect(stamp.sealProgress(of: 2, at: stamp.stampedAt + 0.001) == 1)
        #expect(stamp.stampedAt < DoorStamp.duration - DoorStamp.fadeOut, "every seal lands before the fade")
    }

    @Test(arguments: [1, 3, 5, 6, 40])
    func itIsAlwaysAboutTwoSecondsAndFadesOut(resists: Int) {
        let stamp = DoorStamp(resists: resists)
        #expect(DoorStamp.duration == 2.0)
        #expect(stamp.sealCount <= DoorStamp.maxSeals)
        #expect(stamp.stampedAt <= DoorStamp.duration - DoorStamp.fadeOut)
        #expect(stamp.plaqueOpacity(at: DoorStamp.duration) == 0)
        #expect(stamp.plaqueOpacity(at: 1.0) == 1)
        #expect(stamp.hapticTimes(reduceMotion: false).count == stamp.sealCount)
    }

    @Test func moreThanFiveShowPlusN() {
        #expect(DoorStamp(resists: 5).overflow == 0)
        #expect(DoorStamp(resists: 8).overflow == 3)
        #expect(DoorStamp(resists: 8).sealCount == 5)
    }

    @Test func reduceMotionIsAStaticFadeWithOneHaptic() {
        let stamp = DoorStamp(resists: 3)
        #expect(stamp.reducedOpacity(at: 0.3) == 1, "already stamped, fully there")
        #expect(stamp.reducedOpacity(at: 0) == 0)
        #expect(stamp.reducedOpacity(at: DoorStamp.duration) == 0)
        #expect(stamp.hapticTimes(reduceMotion: true).count == 1)
    }

    @Test func playsOncePerOpenAndAgainAfterTheNextOpen() {
        var visit = DoorStampOpen()
        #expect(visit.claim(unseen: 3)?.resists == 3)
        #expect(visit.isSpent)
        #expect(visit.claim(unseen: 2) == nil, "at most once per open")
        visit.reset()
        #expect(visit.claim(unseen: 2)?.resists == 2)
    }

    @Test func neverOnADayWithZeroResists() {
        var visit = DoorStampOpen()
        #expect(visit.claim(unseen: 0) == nil)
        #expect(!visit.isSpent, "a zero claim does not spend the open")
        let day = "2026-11-6"
        #expect(ResistPayoffLedger.unseen(resisted: 0, day: day, record: .init(day: day, seen: 0)) == 0)
        #expect(ResistPayoffLedger.unseen(resisted: 0, day: day, record: .init(day: "2026-11-5", seen: 4)) == 0)
    }

    @Test func countsOnlyReachesSinceTheLastPayoff() {
        let day = "2026-11-6"
        var visit = DoorStampOpen()
        let first = ResistPayoffLedger.unseen(resisted: 2, day: day, record: .init(day: day, seen: 0))
        #expect(visit.claim(unseen: first)?.resists == 2)
        // The store records 2 as seen; a later open with 5 owes only 3.
        visit.reset()
        let later = ResistPayoffLedger.unseen(resisted: 5, day: day, record: .init(day: day, seen: 2))
        #expect(visit.claim(unseen: later)?.resists == 3)
        visit.reset()
        let none = ResistPayoffLedger.unseen(resisted: 5, day: day, record: .init(day: day, seen: 5))
        #expect(visit.claim(unseen: none) == nil)
    }
}
