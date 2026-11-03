import Foundation
import Testing
@testable import PofuCore

@Suite("Island-game rounds")
struct RoundLedgerTests {
    let rules = RoundRules()
    let monday = LocalDay(year: 2026, month: 11, day: 2)
    let tuesday = LocalDay(year: 2026, month: 11, day: 3)
    let noon = instant(2026, 11, 2, 12)

    @Test func everyDayGrantsTheBaselineOnce() throws {
        var ledger = RoundLedger()
        #expect(ledger.playable(on: monday, rules: rules) == 2)
        try ledger.play(on: monday, rules: rules)
        #expect(ledger.playable(on: monday, rules: rules) == 1)
        try ledger.play(on: monday, rules: rules)
        #expect(throws: RoundError.noRoundBanked) { try ledger.play(on: monday, rules: rules) }
        #expect(ledger.playable(on: tuesday, rules: rules) == 2)
    }

    @Test func resistedReachesEarnRoundsUpToTheirCap() {
        var ledger = RoundLedger()
        let earned = (0..<9).filter { _ in ledger.earnForResist(on: monday, rules: rules) }.count
        #expect(earned == 6)
        #expect(ledger.playable(on: monday, rules: rules) == 8)
    }

    @Test func unplayedRoundsBankButTwelveAreTheDailyMost() throws {
        var ledger = RoundLedger()
        for _ in 0..<6 { ledger.earnForResist(on: monday, rules: rules) }
        for _ in 0..<6 { ledger.earnForResist(on: tuesday, rules: rules) }
        #expect(ledger.banked == 16)
        #expect(ledger.playable(on: tuesday, rules: rules) == 12)
        for _ in 0..<12 { try ledger.play(on: tuesday, rules: rules) }
        #expect(throws: RoundError.dailyLimitReached) { try ledger.play(on: tuesday, rules: rules) }
        #expect(ledger.banked == 4, "the rest wait for tomorrow")
    }

    @Test func aPlayedRoundCreditsItsCappedYieldToThePouch() throws {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        let credited = try world.clock.playRound(yield: 4, in: &world.state, at: noon.adding(minutes: 1))
        #expect(credited == 4)
        #expect(world.state.stations.pending.rounds == 4)
        let capped = try world.clock.playRound(yield: 40, in: &world.state, at: noon.adding(minutes: 2))
        #expect(capped == 5)
        #expect(world.clock.playableRounds(in: world.state, at: noon.adding(minutes: 3)) == 0)
    }

    @Test func aResistedReachEarnsARoundThroughTheClock() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon), .resisted(at: noon))
        #expect(world.clock.playableRounds(in: world.state, at: noon.adding(minutes: 1)) == 3)
    }

    @Test func noRoundsAtNight() {
        var world = World()
        let late = instant(2026, 11, 2, 23, 30)
        world.advance(to: noon, .signOfLife(at: noon))
        #expect(world.clock.playableRounds(in: world.state, at: late) == 0)
        #expect(throws: RoundError.islandsAsleep) {
            try world.clock.playRound(yield: 3, in: &world.state, at: late)
        }
    }

    @Test func theLedgerAndOldPouchesSurviveSaving() throws {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon), .resisted(at: noon))
        _ = try world.clock.playRound(yield: 3, in: &world.state, at: noon.adding(minutes: 1))
        let data = try JSONEncoder().encode(world.state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        #expect(decoded.rounds == world.state.rounds)
        #expect(decoded.stations.pending.rounds == 3)
        // A pouch saved before rounds existed.
        let old = try JSONDecoder().decode(SeedPouch.self, from: Data(#"{"stations":2,"gathered":1,"sleepBonus":0,"skips":3}"#.utf8))
        #expect(old == SeedPouch(stations: 2, gathered: 1, skips: 3))
    }
}
