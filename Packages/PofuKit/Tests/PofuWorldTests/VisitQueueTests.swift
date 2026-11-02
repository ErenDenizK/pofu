import Foundation
import PofuCore
import Testing
@testable import PofuWorld

@Suite("Visit queue")
struct VisitQueueTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }()

    /// Friday 30 October 2026, 10:40 in Istanbul.
    var friday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 10, minute: 40)) ?? Date()
    }

    /// Day three: garden 2, çay 1, pond open; 15 seeds waiting.
    func world(jar: Int = 60, wellbeing: Double = 78) -> WorldSnapshot {
        IslandSamples.world(
            clock: friday,
            tendedDays: 4,
            levels: [.garden: 2, .cay: 1],
            jar: Energy(jar),
            islands: [.aycicegi],
            wellbeing: wellbeing
        )
    }

    func inputs(_ world: WorldSnapshot, _ edit: (inout VisitInputs) -> Void = { _ in }) -> VisitInputs {
        var inputs = VisitInputs(now: friday, world: world, calendar: calendar)
        edit(&inputs)
        return inputs
    }

    @Test func waitingSeedsMakeAVisitThatOpensWithCollect() {
        let plan = VisitQueue.plan(inputs(world()))
        #expect(plan.landing == .visit)
        #expect(plan.beats.first == .collect(SeedPouch(stations: Energy(12), gathered: Energy(3))))
    }

    @Test func theBuildCountsTheSeedsTheCollectBrings() {
        // 60 in the jar + 15 waiting = 75: the garden's level 3 (66) is
        // covered only after the collect.
        let plan = VisitQueue.plan(inputs(world(jar: 60)))
        #expect(plan.beats == [.collect(SeedPouch(stations: Energy(12), gathered: Energy(3))), .build(.garden, level: 3)])
        var held = world(jar: 60)
        held.isHolding = true
        let noCollect = VisitQueue.plan(inputs(held))
        #expect(noCollect.beats.isEmpty)
        #expect(noCollect.landing == .settled)
    }

    @Test func theCheapestAffordableLevelIsTheBuild() {
        // 200 seeds: garden 3 (66), çay 2 (88), pond 1 (160) all fit.
        let beat = VisitQueue.affordableBuild(in: world(jar: 200), seeds: Energy(200))
        #expect(beat == .build(.garden, level: 3))
        #expect(VisitQueue.affordableBuild(in: world(jar: 0), seeds: Energy(10)) == nil)
    }

    @Test func careComesFirstOnceADay() {
        let low = world(wellbeing: 20)
        let plan = VisitQueue.plan(inputs(low))
        #expect(plan.beats.first == .care)
        let again = VisitQueue.plan(inputs(low) { $0.lastCareBeat = friday.addingTimeInterval(-3600) })
        #expect(again.beats.first != .care)
        let yesterday = VisitQueue.plan(inputs(low) { $0.lastCareBeat = friday.addingTimeInterval(-86_400) })
        #expect(yesterday.beats.first == .care)
    }

    @Test func atMostThreeBeatsInPriorityOrder() {
        let low = world(jar: 60, wellbeing: 20)
        let plan = VisitQueue.plan(inputs(low) {
            $0.news = .stageGrew(3)
            $0.lastRecapSeen = friday.addingTimeInterval(-10 * 86_400)
        })
        #expect(plan.beats.count == VisitQueue.maxBeats)
        #expect(plan.beats == [.care, .collect(SeedPouch(stations: Energy(12), gathered: Energy(3))), .news(.stageGrew(3))])
    }

    @Test func theRepairBannerTakesABeatButNotThePrimary() {
        let plan = VisitQueue.plan(inputs(world()) {
            $0.isGuardBroken = true
            $0.news = .islandArrived(.iskele)
        })
        #expect(plan.showsRepairBanner)
        #expect(plan.beats.count == 2)
        // Never inside the minute.
        let minute = VisitQueue.plan(inputs(world()) {
            $0.isGuardBroken = true
            $0.isMinute = true
        })
        #expect(!minute.showsRepairBanner)
    }

    @Test func aReopenWithinFifteenMinutesLandsSettled() {
        let soon = VisitQueue.plan(inputs(world()) { $0.lastSettled = friday.addingTimeInterval(-14 * 60) })
        #expect(soon.landing == .settled)
        #expect(soon.beats.isEmpty)
        let later = VisitQueue.plan(inputs(world()) { $0.lastSettled = friday.addingTimeInterval(-16 * 60) })
        #expect(later.landing == .visit)
    }

    @Test func nightsAreADeadEnd() {
        var night = world()
        night.isBedtime = true
        let plan = VisitQueue.plan(inputs(night) { $0.isGuardBroken = true })
        #expect(plan.landing == .night)
        #expect(plan.beats.isEmpty)
        #expect(plan.showsRepairBanner)
    }

    @Test func theRecapIsDueOnceAfterSundayEvening() {
        // Sunday 1 November 2026.
        let sundayEvening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 19)) ?? friday
        let sundayNoon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12)) ?? friday
        let monday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9)) ?? friday
        #expect(VisitQueue.recapDue(now: sundayEvening, lastSeen: friday, calendar: calendar))
        #expect(!VisitQueue.recapDue(now: sundayNoon, lastSeen: friday, calendar: calendar))
        #expect(!VisitQueue.recapDue(now: monday, lastSeen: sundayEvening, calendar: calendar))
        #expect(VisitQueue.recapDue(now: monday, lastSeen: friday, calendar: calendar))
        // A first week has nothing to recap.
        #expect(!VisitQueue.recapDue(now: monday, lastSeen: nil, calendar: calendar))
    }

    @Test func theSamePlanForTheSameInputs() {
        let a = VisitQueue.plan(inputs(world(jar: 120)) { $0.news = .stageGrew(3) })
        let b = VisitQueue.plan(inputs(world(jar: 120)) { $0.news = .stageGrew(3) })
        #expect(a == b)
    }

    // MARK: Progress

    @Test func aVisitPlaysItsBeatsThenSettles() {
        let collect = VisitBeat.collect(SeedPouch(stations: Energy(12)))
        var progress = VisitProgress(plan: VisitPlan(landing: .visit, showsRepairBanner: false, beats: [collect, .build(.cay, level: 2)]))
        #expect(progress.current == collect)
        #expect(!progress.complete(.build(.cay, level: 2)))
        #expect(progress.complete(collect))
        #expect(progress.current == .build(.cay, level: 2))
        progress.skip()
        #expect(progress.isSettled)
        #expect(progress.current == nil)
        progress.skip()
        #expect(progress.isSettled)
    }

    // MARK: Today

    @Test func guardedTimeShowsInHonestFifteenMinuteSteps() {
        let today = TodaySummary(beads: [true, true, false, true], guardedMinutes: 22, dailyHourMinutes: 60)
        #expect(today.reaches == 4)
        #expect(today.skips == 3)
        #expect(today.guardedAtLeast == 15)
        #expect(today.segments == 4)
        #expect(today.filledSegments == 1)
        let over = TodaySummary(beads: [], guardedMinutes: 95, dailyHourMinutes: 60)
        #expect(over.guardedAtLeast == 90)
        #expect(over.filledSegments == 4)
        let ninety = TodaySummary(beads: [], guardedMinutes: 0, dailyHourMinutes: 90)
        #expect(ninety.segments == 6)
        #expect(ninety.filledSegments == 0)
    }
}
