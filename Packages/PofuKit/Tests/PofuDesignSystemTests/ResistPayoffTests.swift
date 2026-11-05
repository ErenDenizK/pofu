import Foundation
import Testing
import PofuDesignSystem

@Suite("The resist payoff and the menus' rules")
struct ResistPayoffTests {
    @Test(arguments: [1, 2, 5, 8, 12])
    func theTimelineIsAlwaysOneSecond(resists: Int) {
        let payoff = ResistPayoff(resists: resists)
        #expect(ResistPayoff.duration == 1.0)
        #expect(abs(payoff.end - 1.0) < 1e-9, "\(resists): \(payoff.end)")
        for (time, _) in payoff.moments {
            #expect(time >= 0 && time <= ResistPayoff.duration, "\(resists): \(time)")
        }
        // Every bloom is finished by the end.
        for index in 0..<payoff.potCount {
            #expect(payoff.bloomProgress(of: index, at: ResistPayoff.duration) == 1)
        }
    }

    @Test func fiveResistsBloomLeftToRightAsOneCascade() {
        let payoff = ResistPayoff(resists: 5)
        let starts = (0..<5).map { payoff.bloomStart(of: $0) }
        #expect(starts == starts.sorted())
        #expect(Set(starts).count == 5)
        #expect(starts[0] == 0)
        #expect(abs(starts[4] + ResistPayoff.bloomDuration - 1.0) < 1e-9)
    }

    @Test func oneResistBloomsOnePot() {
        let payoff = ResistPayoff(resists: 1)
        #expect(payoff.potCount == 1)
        #expect(payoff.bloomStart(of: 0) == 0)
        #expect(payoff.moments.contains { $0.moment == .feel })
        #expect(payoff.moments.contains { $0.moment == .seedLands })
    }

    @Test func theSeedFliesBetweenLeavingAndLanding() {
        let payoff = ResistPayoff(resists: 3)
        #expect(payoff.seedProgress(at: 0) == 0)
        #expect(payoff.seedProgress(at: 0.5) > 0)
        #expect(payoff.seedProgress(at: 0.5) < 1)
        #expect(payoff.seedProgress(at: 0.9) == 1)
    }

    @Test func theLedgerOwesOnlyUnseenResists() {
        let day = "2026-11-5"
        #expect(ResistPayoffLedger.unseen(resisted: 4, day: day, record: nil) == 0, "a first launch plays nothing old")
        #expect(ResistPayoffLedger.unseen(resisted: 4, day: day, record: .init(day: day, seen: 4)) == 0)
        #expect(ResistPayoffLedger.unseen(resisted: 5, day: day, record: .init(day: day, seen: 4)) == 1)
        #expect(ResistPayoffLedger.unseen(resisted: 2, day: day, record: .init(day: "2026-11-4", seen: 9)) == 2, "a new day starts again")
        #expect(ResistPayoffLedger.unseen(resisted: 0, day: day, record: .init(day: day, seen: 3)) == 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        #expect(ResistPayoffLedger.day(for: Date(timeIntervalSince1970: 1_793_836_800), calendar: calendar) == "2026-11-5")
    }

    @Test func theSheetSurfaceIsGlassOnlyOverAFrozenWorldAtPartialDetents() {
        typealias Rule = PofuSheetSurfaceRule
        #expect(Rule.mode(sheetFraction: 0.5, worldIsFrozen: true, reduceTransparency: false) == .glass)
        #expect(Rule.mode(sheetFraction: 0.95, worldIsFrozen: true, reduceTransparency: false) == .paper)
        #expect(Rule.mode(sheetFraction: 0.5, worldIsFrozen: false, reduceTransparency: false) == .paper)
        #expect(Rule.mode(sheetFraction: 0.5, worldIsFrozen: true, reduceTransparency: true) == .paper)
    }

    @Test func theBackdropStepsBackByTwelveAndTenPercent() {
        #expect(PofuSheetBackdrop.dim == 0.12)
        #expect(PofuSheetBackdrop.desaturation == 0.10)
        #expect(PofuSheetBackdrop.duration == 0.25)
    }

    @Test func theLoadingScreenIsHonest() {
        typealias Timing = PofuLaunchTiming
        #expect(Timing.reveal(readyAfter: 0.1) == .crossfade)
        #expect(Timing.reveal(readyAfter: 0.4) == .curtain)
        #expect(Timing.revealDuration(.crossfade) == 0.2)
        #expect(Timing.revealDuration(.curtain) == 0.6)
        // No curtain while the crossfade window is open, none once ready.
        #expect(!Timing.showsCurtain(after: 0.1, isReady: false))
        #expect(Timing.showsCurtain(after: 0.5, isReady: false))
        #expect(!Timing.showsCurtain(after: 0.5, isReady: true))
        // The line appears only after two seconds of real loading.
        #expect(!Timing.showsLine(after: 1.9, isReady: false))
        #expect(Timing.showsLine(after: 2.0, isReady: false))
        #expect(!Timing.showsLine(after: 5, isReady: true))
    }
}
