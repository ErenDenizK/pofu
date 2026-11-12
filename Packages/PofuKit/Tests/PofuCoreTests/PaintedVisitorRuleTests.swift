import Foundation
import Testing
@testable import PofuCore

/// The game shows no stand-in for a visitor (route R3): the shipped schedule
/// only brings residents whose painted art exists (`VisitorRules.shipped`;
/// `VisitorArtTests` in PofuWorld holds that set to the baked sprites).
@Suite("Painted visitors only")
struct PaintedVisitorRuleTests {
    let schedule = VisitorSchedule.shipped
    let allHealed = VisitorSchedule.Context(
        healed: Set(VisitorSchedule.standardRoster.map(\.island)),
        islandLevel: 8,
        built: [.garden, .teaStall, .pond, .workshop, .windmill, .pier, .lighthouse, "hive"]
    )
    let kokeAndCaglayan = VisitorSchedule.Context(healed: ["koke", "caglayan"], islandLevel: 5, built: [.garden, .pond, .teaStall])
    let monday = LocalDay(year: 2026, month: 11, day: 2)

    /// Rolls `days` days with Pofu opened every day; `invite` answers each quiet day's letter with `guest`.
    func visits(days: Int, context: VisitorSchedule.Context, seed: UInt64, invite guest: ResidentID? = nil) -> [DailyVisit] {
        var ledger = VisitorLedger(seed: seed)
        var out: [DailyVisit] = []
        for offset in 0..<days {
            let day = monday.adding(days: offset)
            schedule.roll(&ledger, to: day, context: context)
            ledger.noteSeen()
            if let current = ledger.current, current.day == day { out.append(current) }
            if let guest, ledger.inviteOpenSince != nil {
                ledger.hearts[guest] = 1
                _ = ledger.invite(guest, on: day)
            }
        }
        return out
    }

    @Test func aResidentWithoutPaintedArtNeverVisits() {
        let painted = VisitorRules.shipped.visiting ?? []
        for seed in [1, 7, 42, 99, 2026] as [UInt64] {
            for context in [allHealed, kokeAndCaglayan] {
                let seen = Set(visits(days: 400, context: context, seed: seed).map(\.resident))
                #expect(seen.isSubset(of: painted), "seed \(seed): \(seen.subtracting(painted).map(\.rawValue)) visited without painted art")
            }
        }
    }

    @Test func anInvitationForAnUnpaintedResidentIsNotKept() {
        // Sumi has no painted visitor yet: asking for her brings someone painted instead.
        let painted = VisitorRules.shipped.visiting ?? []
        let seen = Set(visits(days: 120, context: kokeAndCaglayan, seed: 7, invite: .sumi).map(\.resident))
        #expect(seen.isSubset(of: painted))
    }

    @Test func noHelpVisitWhileTheKiteHasNoArt() {
        for seed in [1, 7, 42] as [UInt64] {
            let reasons = Set(visits(days: 400, context: allHealed, seed: seed).map(\.reason))
            #expect(!reasons.contains(.help))
        }
    }

    @Test func everyDayStillHasAVisitorOrALetter() {
        // With Sumi hidden the days Koke would have sent her go to the painted ones, never empty.
        for seed in [1, 7, 42] as [UInt64] {
            #expect(visits(days: 60, context: kokeAndCaglayan, seed: seed).count >= 50)
        }
    }

    @Test func beforeAnyIslandIsHealedGezginsPostcardComes() {
        let seen = Set(visits(days: 30, context: VisitorSchedule.Context(), seed: 7).map(\.resident))
        #expect(seen == [.gezgin])
    }

    @Test func theWorldClockShipsTheSameRules() {
        let clock = WorldClock(calendar: Calendar(identifier: .gregorian))
        #expect(clock.visitors.rules.visiting == VisitorRules.shipped.visiting)
    }

    @Test func theDefaultScheduleStillHasEveryone() {
        #expect(VisitorSchedule().rules.visiting == nil)
        #expect(VisitorSchedule().eligible.count == VisitorSchedule.standardRoster.count)
    }
}
