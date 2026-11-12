import Foundation
import Testing
@testable import PofuCore

@Suite("Wonder islands")
struct WonderIslandsTests {
    let day = LocalDay(year: 2026, month: 11, day: 10)

    @Test func aVisitAdvancesOneStageOnADayWithAResistedReach() {
        var state = WonderIslandState(rumouredOn: day.adding(days: -1), arrivedOn: day)
        state = WonderIslands.advance(state: state, day: day, resistedToday: true)
        #expect(state.stage == 1)
        #expect(state.lastAdvanceDay == day)
    }

    @Test func aDayWithoutAResistedReachOnlyPauses() {
        let state = WonderIslandState(rumouredOn: day.adding(days: -1), arrivedOn: day)
        #expect(WonderIslands.advance(state: state, day: day, resistedToday: false) == state)
    }

    @Test func atMostOneStageADay() {
        var state = WonderIslandState(rumouredOn: day.adding(days: -1), arrivedOn: day)
        state = WonderIslands.advance(state: state, day: day, resistedToday: true)
        let again = WonderIslands.advance(state: state, day: day, resistedToday: true)
        #expect(again.stage == 1)
        #expect(WonderIslands.advance(state: state, day: day.adding(days: 1), resistedToday: true).stage == 2)
    }

    @Test func nothingHappensBeforeArrivalOrPastHealed() {
        let unseen = WonderIslandState()
        #expect(WonderIslands.advance(state: unseen, day: day, resistedToday: true).stage == 0)
        let healed = WonderIslandState(arrivedOn: day, stage: WonderIslands.healedStage)
        #expect(WonderIslands.advance(state: healed, day: day.adding(days: 3), resistedToday: true).stage == WonderIslands.healedStage)
    }

    @Test func theRumourNeedsFiveTendedDaysAndTheHarbor() {
        var ledger = WonderLedger()
        WonderIslands.roll(&ledger, to: day, tendedDays: 4, harborOpen: true)
        #expect(ledger[.koke].rumouredOn == nil)
        WonderIslands.roll(&ledger, to: day, tendedDays: 9, harborOpen: false)
        #expect(ledger[.koke].rumouredOn == nil)
        WonderIslands.roll(&ledger, to: day, tendedDays: 5, harborOpen: true)
        #expect(ledger[.koke].rumouredOn == day)
        #expect(ledger[.koke].arrivedOn == nil)
        // Same day again: still only the rumour. The next day: arrival.
        WonderIslands.roll(&ledger, to: day, tendedDays: 5, harborOpen: true)
        #expect(ledger[.koke].arrivedOn == nil)
        WonderIslands.roll(&ledger, to: day.adding(days: 1), tendedDays: 6, harborOpen: true)
        #expect(ledger[.koke].arrivedOn == day.adding(days: 1))
    }

    @Test func oldSavesDecodeWithNoWondersAndNoResistedCount() throws {
        var state = GameState()
        state.wonders.islands[.koke] = WonderIslandState(rumouredOn: day, arrivedOn: day, stage: 2, lastAdvanceDay: day)
        let data = try JSONEncoder().encode(state)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["wonders"] = nil
        let old = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(GameState.self, from: old)
        #expect(decoded.wonders == WonderLedger())
        let roundTrip = try JSONDecoder().decode(GameState.self, from: data)
        #expect(roundTrip.wonders[.koke].stage == 2)

        let oldDay = #"{"day":{"year":2026,"month":11,"day":3},"observed":true,"estimatedGuardedMinutes":0,"measuredGuardedMinutes":0,"overLimitOpens":0,"gatheredSeeds":0}"#
        let counters = try JSONDecoder().decode(GameDay.self, from: Data(oldDay.utf8))
        #expect(counters.resistedReaches == 0)
    }

    // MARK: Çağlayan

    private func healedKoke(_ ledger: inout WonderLedger, on day: LocalDay) {
        ledger.islands[.koke] = WonderIslandState(rumouredOn: day.adding(days: -9), arrivedOn: day.adding(days: -8), stage: WonderIslands.healedStage, lastAdvanceDay: day.adding(days: -1))
    }

    @Test func caglayanWaitsForKokeToBeHealedAndTheEighthTendedDay() {
        var ledger = WonderLedger()
        // Koke asleep: no rumour, however many days.
        ledger.islands[.koke] = WonderIslandState(rumouredOn: day.adding(days: -9), arrivedOn: day.adding(days: -8), stage: 3)
        WonderIslands.roll(&ledger, to: day, tendedDays: WonderIslands.caglayanFallbackTendedDays - 1, harborOpen: true)
        #expect(ledger[.caglayan].rumouredOn == nil)
        healedKoke(&ledger, on: day)
        WonderIslands.roll(&ledger, to: day, tendedDays: 7, harborOpen: true)
        #expect(ledger[.caglayan].rumouredOn == nil)
        WonderIslands.roll(&ledger, to: day, tendedDays: 8, harborOpen: true)
        #expect(ledger[.caglayan].rumouredOn == day)
    }

    // MARK: Fillers never block the main road, and the islands sleep

    @Test func caglayanComesAtTendedDayTwelveWhenKokeIsIgnored() {
        var world = World()
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
        world.advance(to: start, .signOfLife(at: start))
        // The harbor is open from the start: this test is about Koke, not the quay.
        world.state.stations.arrivals[.harbor] = 0
        world.state.stations.arrivalOrder.append(.harbor)
        var rumouredAtTendedDays: Int?
        var arrival: (rumoured: LocalDay, arrived: LocalDay)?
        for day in 0..<30 {
            // A resisted reach every day; Koke is never visited.
            let morning = start.addingTimeInterval(Double(day) * 86_400 + 3_600)
            world.advance(to: morning, .resisted(at: morning))
            let noon = morning.addingTimeInterval(3 * 3_600)
            world.advance(to: noon, .signOfLife(at: noon))
            let state = world.state.wonders[.caglayan]
            if rumouredAtTendedDays == nil, state.rumouredOn != nil {
                rumouredAtTendedDays = world.state.tendedDays
            }
            if let rumoured = state.rumouredOn, let arrived = state.arrivedOn {
                arrival = (rumoured, arrived)
                break
            }
        }
        #expect(world.state.wonders[.koke].stage == 0)
        #expect(rumouredAtTendedDays == WonderIslands.caglayanFallbackTendedDays)
        #expect(arrival != nil)
        if let arrival {
            #expect(arrival.arrived == arrival.rumoured.adding(days: WonderIslands.caglayanArrivalDays))
        }
    }

    @Test func kokeStillGatesCaglayanBeforeDayTwelve() {
        var ledger = WonderLedger()
        ledger.islands[.koke] = WonderIslandState(rumouredOn: day.adding(days: -9), arrivedOn: day.adding(days: -8), stage: 2)
        for tended in 0..<WonderIslands.caglayanFallbackTendedDays {
            WonderIslands.roll(&ledger, to: day, tendedDays: tended, harborOpen: true)
            #expect(ledger[.caglayan].rumouredOn == nil, "rumour at tended day \(tended)")
        }
        // Even at the fallback day the harbor must be open.
        WonderIslands.roll(&ledger, to: day, tendedDays: WonderIslands.caglayanFallbackTendedDays, harborOpen: false)
        #expect(ledger[.caglayan].rumouredOn == nil)
        WonderIslands.roll(&ledger, to: day, tendedDays: WonderIslands.caglayanFallbackTendedDays, harborOpen: true)
        #expect(ledger[.caglayan].rumouredOn == day)
    }

    @Test func wondersSleepAtBedtime() {
        var world = World()
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
        world.advance(to: start, .signOfLife(at: start))
        let today = LocalDay(containing: start, in: .istanbul)
        world.state.wonders.islands[.koke] = WonderIslandState(rumouredOn: today.adding(days: -2), arrivedOn: today.adding(days: -1))
        world.state.wonders.islands[.caglayan] = WonderIslandState(rumouredOn: today.adding(days: -2), arrivedOn: today.adding(days: -1))
        let reach = start.addingTimeInterval(60)
        world.advance(to: reach, .resisted(at: reach))
        #expect(world.snapshot.koke.canAdvance && !world.snapshot.koke.isAsleep)
        #expect(world.snapshot.caglayan.canAdvance && !world.snapshot.caglayan.isAsleep)
        // 23:30 the same day.
        var parts = Calendar.istanbul.dateComponents([.year, .month, .day], from: start)
        parts.hour = 23
        parts.minute = 30
        let night = Calendar.istanbul.date(from: parts)!
        world.advance(to: night, .resisted(at: night))
        #expect(world.snapshot.isBedtime)
        #expect(world.snapshot.koke.isAsleep && !world.snapshot.koke.canAdvance)
        #expect(world.snapshot.caglayan.isAsleep && !world.snapshot.caglayan.canAdvance)
        world.advance(to: night, GameEvent(at: night, kind: .tendedWonder(.koke)))
        world.advance(to: night, GameEvent(at: night, kind: .tendedWonder(.caglayan)))
        #expect(world.state.wonders[.koke].stage == 0)
        #expect(world.state.wonders[.caglayan].stage == 0)
    }

    @Test func caglayanArrivesTwoDaysAfterItsRumour() {
        var ledger = WonderLedger()
        healedKoke(&ledger, on: day)
        WonderIslands.roll(&ledger, to: day, tendedDays: 8, harborOpen: true)
        WonderIslands.roll(&ledger, to: day.adding(days: 1), tendedDays: 9, harborOpen: true)
        #expect(ledger[.caglayan].arrivedOn == nil)
        WonderIslands.roll(&ledger, to: day.adding(days: 2), tendedDays: 10, harborOpen: true)
        #expect(ledger[.caglayan].arrivedOn == day.adding(days: 2))
        // A rolled arrival never moves.
        WonderIslands.roll(&ledger, to: day.adding(days: 5), tendedDays: 13, harborOpen: true)
        #expect(ledger[.caglayan].arrivedOn == day.adding(days: 2))
    }

    @Test func kokeStillRollsOnItsOwnWhileCaglayanIsHidden() {
        var ledger = WonderLedger()
        WonderIslands.roll(&ledger, to: day, tendedDays: 5, harborOpen: true)
        #expect(ledger[.koke].rumouredOn == day)
        #expect(ledger[.caglayan] == WonderIslandState())
    }

    @Test func caglayanStagesAdvanceOneAtATimeOnlyWithAResistedReach() {
        let arrived = WonderIslandState(rumouredOn: day.adding(days: -2), arrivedOn: day)
        var state = arrived
        // A quiet day: the flow round can be played but pays no stage.
        #expect(WonderIslands.advance(state: state, day: day, resistedToday: false).stage == 0)
        for stage in 1...WonderIslands.healedStage {
            let today = day.adding(days: stage)
            state = WonderIslands.advance(state: state, day: today, resistedToday: true)
            #expect(state.stage == stage)
            // A second finished round the same day does not move it again.
            #expect(WonderIslands.advance(state: state, day: today, resistedToday: true).stage == stage)
        }
        #expect(WonderIslands.advance(state: state, day: day.adding(days: 9), resistedToday: true).stage == WonderIslands.healedStage)
    }

    @Test func finishingAFlowRoundThroughTheClockAdvancesCaglayanOneStage() {
        var world = World()
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
        world.advance(to: start, .signOfLife(at: start))
        let today = LocalDay(containing: start, in: .istanbul)
        world.state.wonders.islands[.caglayan] = WonderIslandState(rumouredOn: today.adding(days: -2), arrivedOn: today.adding(days: -1))
        // A finished round on a quiet day pays nothing.
        let noon = start.addingTimeInterval(60)
        world.advance(to: noon, GameEvent(at: noon, kind: .tendedWonder(.caglayan)))
        #expect(world.state.wonders[.caglayan].stage == 0)
        // A resisted reach makes the day count; the next finished round pays one stage.
        let later = noon.addingTimeInterval(60)
        world.advance(to: later, .resisted(at: later))
        #expect(world.snapshot.caglayan.canAdvance)
        let done = later.addingTimeInterval(60)
        world.advance(to: done, GameEvent(at: done, kind: .tendedWonder(.caglayan)))
        #expect(world.state.wonders[.caglayan].stage == 1)
        #expect(!world.snapshot.caglayan.canAdvance)
        let again = done.addingTimeInterval(60)
        world.advance(to: again, GameEvent(at: again, kind: .tendedWonder(.caglayan)))
        #expect(world.state.wonders[.caglayan].stage == 1)
        #expect(world.state.wonders[.koke].stage == 0)
    }

    @Test func caglayanHandsOverItsKeepsakeAtTheFourthStage() {
        var game = GameState()
        game.wonders.islands[.caglayan] = WonderIslandState(rumouredOn: day, arrivedOn: day, stage: 3)
        #expect(!WonderIslands.status(of: .caglayan, game: game, day: day).giftUnlocked)
        game.wonders.islands[.caglayan]?.stage = WonderIslands.healedStage
        let healed = WonderIslands.status(of: .caglayan, game: game, day: day)
        #expect(healed.isHealed)
        #expect(healed.giftUnlocked)
        #expect(!WonderIslands.status(game: game, day: day).giftUnlocked)
    }

    @Test func aSaveWithKokeOnlyDecodesAndCaglayanIsHidden() throws {
        var state = GameState()
        state.wonders.islands[.koke] = WonderIslandState(rumouredOn: day, arrivedOn: day, stage: 1)
        let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(decoded.wonders[.caglayan] == WonderIslandState())
        #expect(WonderIslands.status(of: .caglayan, game: decoded, day: day).phase == .hidden)
    }
}
