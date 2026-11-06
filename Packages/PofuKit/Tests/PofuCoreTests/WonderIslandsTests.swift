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
}
