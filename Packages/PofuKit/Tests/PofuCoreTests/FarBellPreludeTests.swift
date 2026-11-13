import Foundation
import Testing
@testable import PofuCore

/// The far bell's road (docs/design/days-17-21-v1.md): the step is a pure
/// function of the snapshot, and the notes of each step are data.
@Suite("Far bell prelude")
struct FarBellPreludeTests {
    static let path = PlayerPath.tester()

    @Test func theTesterHearsOneStepADayFromDaySeventeen() {
        for day in Self.path {
            let expected: Int? = (17...20).contains(day.day) ? day.day - 16 : nil
            #expect(FarBellPrelude.step(in: day.morning) == expected, "day \(day.day) morning")
            #expect(FarBellPrelude.step(in: day.night) == expected, "day \(day.day) night")
        }
    }

    @Test func theBellsOwnDayIsDayTwentyOne() {
        for day in Self.path {
            let isDay = day.day == 21
            #expect(FarBellPrelude.isBellDay(in: day.morning) == isDay, "day \(day.day) morning")
            #expect(FarBellPrelude.isBellDay(in: day.visit) == isDay, "day \(day.day) visit")
            #expect(FarBellPrelude.isBellDay(in: day.night) == isDay, "day \(day.day) night")
        }
    }

    @Test func noStepUntilBothIslandsAreHealed() {
        for tended in 15...21 {
            #expect(FarBellPrelude.step(tendedDays: tended, bothHealed: false, bell: .silent) == nil)
        }
    }

    @Test func noStepOnceTheBellRang() {
        for tended in 15...21 {
            #expect(FarBellPrelude.step(tendedDays: tended, bothHealed: true, bell: .ringing) == nil)
            #expect(FarBellPrelude.step(tendedDays: tended, bothHealed: true, bell: .heard) == nil)
        }
    }

    @Test func aLateHealerHearsTheLastStepsOnly() {
        #expect(FarBellPrelude.step(tendedDays: 15, bothHealed: true, bell: .silent) == nil)
        #expect(FarBellPrelude.step(tendedDays: 18, bothHealed: true, bell: .silent) == 3)
        #expect(FarBellPrelude.step(tendedDays: 19, bothHealed: true, bell: .silent) == 4)
        #expect(FarBellPrelude.step(tendedDays: FarBell.tendedDays, bothHealed: true, bell: .silent) == nil)
    }

    @Test func everyStepOpensWithPofusFourNotes() {
        for step in 1...FarBellPrelude.steps {
            let hummed = FarBellTune.prelude(step: step).filter { !$0.isFar }
            #expect(hummed.map(\.step) == FarBellTune.hum, "step \(step)")
            #expect(hummed.map(\.at) == [0, 1, 2, 3].map { Double($0) * FarBellTune.humGap }, "step \(step)")
        }
    }

    @Test func eachStepAnswersOneMoreNote() {
        let counts = (1...FarBellPrelude.steps).map { FarBellTune.prelude(step: $0).filter(\.isFar).count }
        #expect(counts == [0, 1, 2, 4])
        let second = FarBellTune.prelude(step: 2).filter(\.isFar)
        #expect(second.first?.at == 3 * FarBellTune.humGap + FarBellTune.breath)
        #expect(second.first?.step == FarBellTune.farSong[0])
    }

    @Test func stepFourGetsTheThirdNoteWrong() {
        let far = FarBellTune.prelude(step: 4).filter(\.isFar).map(\.step)
        #expect(far == [0, 2, FarBellTune.wrongThird, 4])
        #expect(FarBellTune.farSong[2] != FarBellTune.wrongThird)
        let third = FarBellTune.prelude(step: 3).filter(\.isFar).map(\.step)
        #expect(third == [0, 2], "only step four is wrong")
    }

    @Test func theBellPlaysTheSongAndOneNoteMore() {
        let bell = FarBellTune.bell()
        #expect(bell.map(\.step) == [0, 2, 3, 4, 5])
        #expect(bell.allSatisfy(\.isFar))
        #expect(bell.first?.at == FarBellTune.bellLead)
        #expect(FarBellTune.length(of: bell) == FarBellTune.bellLead + 4 * FarBellTune.farGap)
    }

    @Test func notesNeverCrowd() {
        let tunes = (1...FarBellPrelude.steps).map { FarBellTune.prelude(step: $0) } + [FarBellTune.bell()]
        for tune in tunes {
            let times = tune.map(\.at).sorted()
            for (a, b) in zip(times, times.dropFirst()) {
                #expect(b - a >= 0.3, "notes \(a) and \(b) are too close")
            }
        }
    }

    @Test func anUnknownStepIsSilent() {
        for step in [-1, 0, 5, 99] {
            #expect(FarBellTune.prelude(step: step).isEmpty)
        }
        #expect(FarBellTune.length(of: []) == 0)
    }
}
