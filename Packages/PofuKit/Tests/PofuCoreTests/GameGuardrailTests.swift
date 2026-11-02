import Foundation
import Testing
@testable import PofuCore

/// Property tests for the guardrails (game design §4 and §13,
/// app-game-boundary A20, decision audit C1): over random histories,
/// staring at Pofu earns nothing, unobserved time earns nothing, the meters
/// stay in range, and nothing built is ever taken away.
@Suite("Game guardrails")
struct GameGuardrailTests {
    static let seeds: [UInt64] = [1, 2, 3, 5, 8, 13, 21, 34]

    /// Everything that rewards absence, at one moment.
    struct Rewards: Equatable {
        var seeds: Energy
        var carry: Int
        var calmTenths: Int
        var calmRun: Int
        var quietRun: Int
        var wellbeing: Double

        init(_ state: GameState) {
            seeds = state.stations.pending.total + state.stations.jar
            carry = state.stations.productionCarry
            calmTenths = state.calm.tenths
            calmRun = state.calm.runMinutes
            quietRun = state.quietRunMinutes
            wellbeing = state.care.wellbeing
        }
    }

    /// A world after a random day and a half, then quiet until a waking
    /// hour, with Pofu observing and no pass running.
    func randomWorld(seed: UInt64, measurement: GuardedMeasurement = .softGate) -> (World, Date) {
        var world = World(rules: GameRules(measurement: measurement))
        let start = instant(2026, 11, 2, 7)
        world.advance(to: start.adding(hours: 36), applying: randomScript(seed: seed, from: start, hours: 36))
        var rng = SplitMix64(seed: seed &* 31)
        // A waking moment between 08:00 and 10:00 the next day.
        let at = instant(2026, 11, 4, 8).addingTimeInterval(Double(Int.random(in: 0..<(2 * 3600), using: &rng)))
        world.advance(to: at, .signOfLife(at: at), .foregroundEnded(at: at))
        return (world, at)
    }

    // MARK: - Looking earns nothing (A9, A20)

    @Test(arguments: seeds)
    func staringAtPofuEarnsNothingPastTheGrace(seed: UInt64) {
        let (base, at) = randomWorld(seed: seed)
        var world = base
        var rng = SplitMix64(seed: seed &+ 99)
        let stare = Int.random(in: 3...240, using: &rng)
        world.advance(to: at, .foregroundBegan(at: at))
        // The grace: the first two minutes count as away.
        world.advance(to: at.adding(minutes: 2))
        let before = Rewards(world.state)
        let calmBefore = world.state.calm
        for minute in 3...stare {
            let delta = world.advance(to: at.adding(minutes: Double(minute)))
            #expect(delta.seeds == .zero)
            #expect(delta.awayMinutes == 0)
        }
        #expect(Rewards(world.state) == before)
        // Looking never punishes either: calm does not reset.
        #expect(world.state.calm == calmBefore)
    }

    @Test(arguments: seeds)
    func staringEarnsNoMoreThanLeaving(seed: UInt64) {
        let (base, at) = randomWorld(seed: seed)
        var staring = base
        var away = base
        staring.advance(to: at.adding(hours: 1), .foregroundBegan(at: at))
        away.advance(to: at.adding(hours: 1), .foregroundBegan(at: at), .foregroundEnded(at: at.adding(minutes: 1)))
        #expect(staring.seeds <= away.seeds)
        #expect(staring.state.calm.tenths <= away.state.calm.tenths)
    }

    // MARK: - Unobserved time earns nothing (C1, U2)

    @Test(arguments: seeds)
    func theTimeAfterAnExpiryEarnsNothingUntilASignOfLife(seed: UInt64) {
        let (base, at) = randomWorld(seed: seed)
        var world = base
        var rng = SplitMix64(seed: seed &+ 7)
        let minutes = Int.random(in: 1...30, using: &rng)
        let gap = Int.random(in: 1...(10 * 60), using: &rng)
        let end = at.adding(minutes: Double(minutes))
        world.advance(to: end, .opened(gamePass(at: at, minutes: minutes)))
        let before = Rewards(world.state)
        let delta = world.advance(to: end.adding(minutes: Double(gap)))
        #expect(delta.unobservedMinutes == gap)
        #expect(delta.seeds == .zero)
        var after = Rewards(world.state)
        // Runs break; nothing else moves.
        after.calmRun = before.calmRun
        after.quietRun = before.quietRun
        #expect(after == before)
    }

    @Test(arguments: seeds)
    func pastTheObservationWindowNothingAccrues(seed: UInt64) {
        let (base, at) = randomWorld(seed: seed)
        var world = base
        let lapse = at.addingTimeInterval(world.rules.quiet.observationWindow)
        world.advance(to: lapse)
        let seedsBefore = world.seeds
        let carryBefore = world.state.stations.productionCarry
        let calmBefore = world.state.calm.tenths
        let nightsBefore = world.state.calmNights
        let delta = world.advance(to: lapse.adding(hours: 24 * 4))
        #expect(delta.awayMinutes == 0)
        #expect(delta.seeds == .zero)
        #expect(world.seeds == seedsBefore)
        #expect(world.state.stations.productionCarry == carryBefore)
        #expect(world.state.calm.tenths == calmBefore)
        #expect(world.state.calmNights == nightsBefore)
    }

    @Test(arguments: seeds)
    func theModelNeverCountsMoreAwayTimeThanItCouldSee(seed: UInt64) {
        let start = instant(2026, 11, 2, 7)
        var world = World()
        let script = randomScript(seed: seed, from: start, hours: 96)
        let delta = world.advance(to: start.adding(hours: 100), applying: script)
        #expect(delta.awayMinutes + delta.guardedMinutes + delta.pausedMinutes + delta.unobservedMinutes == 100 * 60)
        // Every away minute is backed by a sign of life within the window:
        // with no signs of life at all, nothing is away.
        var silent = World()
        let none = silent.advance(to: start.adding(hours: 100), applying: script.filter { event in
            switch event.kind {
            case .signOfLife, .resisted, .opened: false
            default: true
            }
        })
        #expect(none.awayMinutes == 0)
        #expect(none.seeds == .zero)
    }

    // MARK: - Ranges and monotonicity (A4, ADR-0017)

    @Test(arguments: seeds)
    func metersStayInRangeAndNothingBuiltGoesBack(seed: UInt64) throws {
        var world = World(rules: GameRules(releasedIslands: [.kitap]))
        let start = instant(2026, 11, 2, 7)
        let script = randomScript(seed: seed, from: start, hours: 24 * 12)
        var rng = SplitMix64(seed: seed &+ 3)
        var cursor = start
        var levels = world.state.stations.levels
        var islands = world.state.stations.arrivalOrder
        var tended = 0
        var nights = 0
        var remaining = script
        let end = start.adding(hours: 24 * 12)
        while cursor < end {
            cursor = min(end, cursor.addingTimeInterval(Double(Int.random(in: 600...(6 * 3600), using: &rng))))
            let due = remaining.filter { $0.at <= cursor }
            remaining.removeAll { $0.at <= cursor }
            world.advance(to: cursor, applying: due)
            _ = world.collect(at: cursor)
            // Build the cheapest open level, when the jar allows.
            let next = world.snapshot.stations.filter { $0.isOpen && $0.canAfford }.min { ($0.nextCost ?? 0) < ($1.nextCost ?? 0) }
            if let next, !world.snapshot.isBedtime {
                try world.build(next.id, at: cursor)
            }

            let care = world.state.care.wellbeing
            #expect(care >= 5 && care <= 100)
            #expect((10...20).contains(world.state.calm.tenths))
            #expect(world.state.stations.jar >= .zero)
            for (station, level) in levels {
                #expect(world.state.stations.level(of: station) >= level)
            }
            #expect(Array(world.state.stations.arrivalOrder.prefix(islands.count)) == islands)
            #expect(world.state.tendedDays >= tended)
            #expect(world.state.calmNights >= nights)
            levels = world.state.stations.levels
            islands = world.state.stations.arrivalOrder
            tended = world.state.tendedDays
            nights = world.state.calmNights
        }
    }

    @Test(arguments: seeds)
    func calmNeverResetsWithoutAnOpen(seed: UInt64) {
        var world = World()
        let start = instant(2026, 11, 2, 7)
        let script = randomScript(seed: seed, from: start, hours: 48).filter { event in
            if case .opened = event.kind { return false }
            return true
        }
        var cursor = start
        var last = 10
        for event in script {
            world.advance(to: event.at, applying: [event])
            #expect(world.state.calm.tenths >= last)
            last = world.state.calm.tenths
            cursor = event.at
        }
        world.advance(to: cursor.adding(hours: 2))
        #expect(world.state.calm.tenths >= last)
    }
}
