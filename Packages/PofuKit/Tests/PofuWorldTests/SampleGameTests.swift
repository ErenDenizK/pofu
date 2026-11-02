import Foundation
import PofuCore
import Testing
@testable import PofuWorld

/// The screenshots' world is played through the real clock; these checks
/// keep it showing what the screenshots promise.
@Suite("Sample game")
struct SampleGameTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    @Test func theFifthMorningHasSeedsWaitingAndAWeekOfBuilds() {
        let game = IslandSamples.playedWeek(calendar: calendar)
        let world = game.snapshot
        #expect(!world.isBedtime)
        #expect(world.tendedDays == 4)
        #expect(!world.pending.isEmpty)
        #expect(!world.isHolding)
        let cay = world.stations.first { $0.id == .cay }
        #expect((cay?.level ?? 0) >= 1)
        let garden = world.stations.first { $0.id == .garden }
        #expect((garden?.level ?? 0) >= 2)
        #expect(world.guardedMinutesToday == 15)
        #expect(game.today.skips == 3)
        #expect(game.today.filledSegments == 1)
    }

    @Test func theVisitCollectsThenBuilds() {
        let game = IslandSamples.playedWeek(calendar: calendar)
        let plan = VisitQueue.plan(VisitInputs(now: game.now, world: game.snapshot, calendar: calendar))
        #expect(plan.landing == .visit)
        guard plan.beats.count >= 2, case .collect = plan.beats[0], case .build(let station, let level) = plan.beats[1] else {
            Issue.record("expected collect, then build: \(plan.beats)")
            return
        }
        var played = game
        let pouch = played.collect()
        #expect(pouch != nil)
        let receipt = played.build(station)
        #expect(receipt?.level == level)
    }

    @Test func collectAndBuildGoThroughTheClock() throws {
        var game = IslandSamples.playedWeek(calendar: calendar)
        let before = game.snapshot
        let pouch = try #require(game.collect())
        #expect(game.snapshot.jar == before.jar + pouch.total)
        #expect(game.snapshot.pending.isEmpty)
        #expect(game.collect() == nil)
    }
}
