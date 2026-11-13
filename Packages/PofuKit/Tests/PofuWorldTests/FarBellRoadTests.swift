import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// The far bell's road in the world (docs/design/days-17-21-v1.md): the
/// visit queue carries the step, the cue follows the beats, the night line
/// listens, and the stage keeps what plays.
@Suite("Far bell road")
@MainActor
struct FarBellRoadTests {
    static let path = PlayerPath.tester()
    static let istanbul: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }()

    private func plan(_ world: WorldSnapshot, preludeHeard: Int = 0) -> VisitPlan {
        VisitQueue.plan(VisitInputs(now: world.clock ?? Date(), world: world, preludeHeard: preludeHeard, calendar: Self.istanbul))
    }

    @Test func theTestersMorningsCarryTheStep() throws {
        for day in Self.path where (17...20).contains(day.day) {
            let beats = plan(day.morning).beats
            let step = day.day - 16
            let at = try #require(beats.firstIndex(of: .news(.farNotes(step))), "day \(day.day): \(beats)")
            if let collect = beats.firstIndex(where: { if case .collect = $0 { true } else { false } }) {
                #expect(collect < at, "day \(day.day): the step follows the collect")
            }
            if let build = beats.firstIndex(where: { if case .build = $0 { true } else { false } }) {
                #expect(at < build, "day \(day.day): the step comes before any build")
            }
            #expect(!beats.contains(.bell))
        }
        let bellDay = try #require(Self.path.first { $0.day == 21 })
        let beats = plan(bellDay.morning).beats
        #expect(beats.contains(.bell))
        #expect(!beats.contains { if case .news(.farNotes) = $0 { true } else { false } })
    }

    @Test func aStepIsToldOnce() throws {
        for day in Self.path where (17...20).contains(day.day) {
            let step = day.day - 16
            #expect(!plan(day.morning, preludeHeard: step).beats.contains(.news(.farNotes(step))))
            #expect(plan(day.morning, preludeHeard: step - 1).beats.contains(.news(.farNotes(step))))
        }
    }

    private func steppedVisit(day: Int) throws -> VisitProgress {
        let morning = try #require(Self.path.first { $0.day == day }).morning
        return VisitProgress(plan: plan(morning))
    }

    @Test func takingTheStepsButtonIsItsCue() throws {
        var old = try steppedVisit(day: 18)
        // Get to the step's beat: the collect first, when seeds wait.
        while old.current != .news(.farNotes(2)), old.current != nil {
            var next = old
            next.skip()
            #expect(FarBellCues.cue(from: old, to: next) == nil, "a beat before the step is not its cue")
            old = next
        }
        #expect(old.current == .news(.farNotes(2)))
        var new = old
        new.skip()
        #expect(FarBellCues.cue(from: old, to: new) == .prelude(step: 2))
    }

    @Test func aNewVisitIsNotACue() throws {
        let old = try steppedVisit(day: 18)
        var played = old
        while played.current != .news(.farNotes(2)), played.current != nil { played.skip() }
        played.skip()
        // A fresh landing with the same plan, or another plan, is not "the button was taken".
        let again = VisitProgress(plan: old.plan)
        #expect(FarBellCues.cue(from: played, to: again) == nil)
        #expect(FarBellCues.cue(from: old, to: again) == nil)
    }

    @Test func theBellSoundsWhenItsBeatComesUp() throws {
        let morning = try #require(Self.path.first { $0.day == 21 }).morning
        let withCollect = VisitProgress(plan: VisitPlan(landing: .visit, showsRepairBanner: false, beats: [.collect(SeedPouch()), .bell]))
        var afterCollect = withCollect
        afterCollect.skip()
        #expect(FarBellCues.cue(from: withCollect, to: afterCollect) == .bell, "after the collect the bell comes up")

        let first = VisitProgress(plan: VisitPlan(landing: .visit, showsRepairBanner: false, beats: [.bell]))
        let settled = VisitProgress(plan: VisitPlan(landing: .settled, showsRepairBanner: false, beats: []))
        #expect(FarBellCues.cue(from: settled, to: first) == .bell, "as a visit's first beat")

        var taken = first
        taken.skip()
        #expect(FarBellCues.cue(from: first, to: taken) == nil, "not when its button is taken")

        // The tester's own morning ends on it.
        #expect(plan(morning).beats.contains(.bell))
    }

    private func line(day: Int, hour: Int, night: Bool = true) throws -> HomeDailyLine {
        let found = try #require(Self.path.first { $0.day == day })
        var world = night ? found.night : found.morning
        world.clock = Self.istanbul.date(from: DateComponents(year: 2026, month: 11, day: 1 + day, hour: hour, minute: 0))
        return HomeDailyLine.choose(world: world, skipsToday: 1, calendar: Self.istanbul)
    }

    @Test func theNightLineListensOnTheFourNights() throws {
        for day in 17...20 {
            #expect(try line(day: day, hour: 23) == .listening(step: day - 16), "day \(day)")
        }
        #expect(try line(day: 21, hour: 23) == .bellNight)
        if case .night = try line(day: 16, hour: 23) {} else { Issue.record("day 16 keeps the ordinary night line") }
    }

    @Test func afterMidnightTheOrdinaryNightLineReturns() throws {
        for day in 17...21 {
            let late = try line(day: day, hour: 0)
            if case .night = late {} else { Issue.record("day \(day) at 00:00 is \(late)") }
        }
    }

    @Test func theStageKeepsWhatPlays() {
        let stage = FarBellStage()
        var played: [[FarBellTune.Note]] = []
        stage.onPlay = { played.append($0) }
        stage.play([])
        #expect(played.isEmpty && stage.notes.isEmpty, "an empty tune is ignored")

        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let tune = FarBellTune.prelude(step: 2)
        stage.play(tune, at: start)
        #expect(played == [tune])
        #expect(stage.notes == tune)
        #expect(stage.age(at: start.addingTimeInterval(0.5)) == 0.5)
        #expect(stage.age(at: start.addingTimeInterval(FarBellTune.length(of: tune) + 2)) == nil)

        stage.hold(FarBellTune.bell(), age: 2)
        #expect(played.count == 1, "a held tune does not sound")
        #expect(stage.age(at: Date()) == 2)
        stage.clear()
        #expect(stage.age(at: Date()) == nil)
    }
}
