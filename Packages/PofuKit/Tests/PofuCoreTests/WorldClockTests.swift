import Foundation
import Testing
@testable import PofuCore

/// The game model's facade: the minute grid, what Pofu can and cannot see,
/// A20, nights, the breath's counts, collection, builds, and the gate-log
/// adapter.
@Suite("World clock")
struct WorldClockTests {
    let noon = instant(2026, 11, 2, 12)

    // MARK: - Growth while away

    @Test func nothingHappensBeforeTheFirstSignOfLife() {
        var world = World()
        world.advance(to: noon)
        let delta = world.advance(to: noon.adding(hours: 5))
        #expect(delta.seeds == .zero)
        #expect(delta.unobservedMinutes == 300)
        #expect(world.snapshot.activity == .notSetUp)
        #expect(world.state.calm.tenths == 10)
        #expect(world.state.care.wellbeing == 70)
    }

    @Test func anHourAwayAtNoon() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        let delta = world.advance(to: noon.adding(hours: 1))
        #expect(delta.awayMinutes == 60)
        #expect(delta.calmSteps == 3)
        #expect(world.state.calm.multiplier == 1.3)
        #expect(abs(world.state.care.wellbeing - 75) < 1e-9)
        #expect(delta.gatheredSeeds == 6)
        // 19 minutes at ×1.0, 20 at ×1.1, 20 at ×1.2, 1 at ×1.3 of 6 an
        // hour: 6.63 seeds, the fraction carried.
        #expect(delta.stationSeeds == 6)
        #expect(world.state.stations.productionCarry == 378_000)
        #expect(world.snapshot.activity == .away)
        #expect(abs(world.snapshot.seedsPerHour - 7.8) < 1e-9)
    }

    @Test func pofuGathersAtMostFortyEightADay() {
        var world = World(rules: GameRules(bedtime: DailyWindow(start: LocalTime(hour: 0), end: LocalTime(hour: 0))))
        let morning = instant(2026, 11, 2, 0)
        world.advance(to: morning, .signOfLife(at: morning))
        let delta = world.advance(to: morning.adding(hours: 24))
        #expect(delta.gatheredSeeds == 48)
    }

    // MARK: - Honest measurement (decision audit C1, U2)

    /// U2's test: grant a 5-minute pass, emit no events for an hour. Under
    /// the soft gate nothing closes the app, so the hour after the expiry
    /// is unobserved and earns nothing.
    @Test func theTimeAfterAnExpiryIsUnobservedUnderTheSoftGate() {
        var world = World()
        let start = noon.adding(hours: -1)
        world.advance(to: noon, .signOfLife(at: start))
        let pass = gamePass(at: noon, minutes: 5)
        world.advance(to: noon, .opened(pass))
        #expect(world.state.calm.tenths == 10)
        let delta = world.advance(to: noon.adding(hours: 1))
        #expect(delta.guardedMinutes == 5)
        #expect(delta.unobservedMinutes == 55)
        #expect(delta.awayMinutes == 0)
        #expect(delta.seeds == .zero)
        #expect(world.state.calm.tenths == 10)
        #expect(world.snapshot.activity == .unobserved)

        // The next sign of life starts a fresh stretch.
        world.advance(to: noon.adding(hours: 1), .signOfLife(at: noon.adding(hours: 1)))
        let after = world.advance(to: noon.adding(hours: 2))
        #expect(after.awayMinutes == 60)
        #expect(after.gatheredSeeds == 6)
    }

    @Test func screenTimeClosesTheAppSoTheTimeAfterAPassIsObserved() {
        var world = World(rules: GameRules(measurement: .screenTime))
        world.advance(to: noon, .signOfLife(at: noon))
        world.advance(to: noon, .opened(gamePass(at: noon, minutes: 5)))
        let delta = world.advance(to: noon.adding(hours: 1))
        #expect(delta.guardedMinutes == 5)
        #expect(delta.awayMinutes == 55)
        #expect(delta.unobservedMinutes == 0)
        #expect(world.state.calm.tenths == 12)
    }

    @Test func endingAPassEarlyInPofuResumesAtOnce() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        let pass = gamePass(at: noon, minutes: 15)
        world.advance(to: noon, .opened(pass))
        let delta = world.advance(to: noon.adding(hours: 1), .endedEarly(pass, at: noon.adding(minutes: 4)))
        #expect(delta.guardedMinutes == 4)
        #expect(delta.awayMinutes == 56)
    }

    @Test func comingBackToPofuAfterAnExpiryResumes() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        world.advance(to: noon, .opened(gamePass(at: noon, minutes: 5)))
        let delta = world.advance(
            to: noon.adding(hours: 1),
            .returned(at: noon.adding(minutes: 20))
        )
        #expect(delta.guardedMinutes == 5)
        #expect(delta.unobservedMinutes == 15)
        #expect(delta.awayMinutes == 40)
    }

    @Test func aPassThatExpiresWhilePofuIsOnScreenHandsOverAtOnce() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        world.advance(to: noon, .opened(gamePass(at: noon, minutes: 5)))
        world.advance(to: noon.adding(minutes: 4), .foregroundBegan(at: noon.adding(minutes: 4)))
        let delta = world.advance(to: noon.adding(minutes: 7), .foregroundEnded(at: noon.adding(minutes: 6.5)))
        #expect(delta.guardedMinutes == 1)
        #expect(delta.awayMinutes == 2)
        #expect(!world.state.awaitingReturn)
    }

    @Test func observationLapsesSeventyTwoHoursAfterTheLastSignOfLife() throws {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        let delta = world.advance(to: noon.adding(hours: 80))
        #expect(delta.awayMinutes == 72 * 60)
        #expect(delta.unobservedMinutes == 8 * 60)
        #expect(world.snapshot.isHolding)
        let result1 = world.collect(at: noon.adding(hours: 80))
        #expect(result1 == nil)

        let back = noon.adding(hours: 80)
        world.advance(to: back, .signOfLife(at: back))
        let result2 = world.collect(at: back)
        let collected = try #require(result2)
        #expect(collected.total > 0)
        #expect(world.state.stations.jar == collected.total)
    }

    // MARK: - A20: looking earns nothing

    @Test func pastTwoMinutesInTheForegroundTheWorldWaits() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon), .foregroundBegan(at: noon))
        let delta = world.advance(to: noon.adding(hours: 1))
        #expect(delta.awayMinutes == 2)
        #expect(delta.pausedMinutes == 58)
        #expect(delta.seeds == .zero)
        #expect(world.state.calm.tenths == 10)
        #expect(world.state.calm.runMinutes == 2)
        #expect(world.snapshot.activity == .paused)
        #expect(world.snapshot.seedsPerHour == 0)

        // Calm does not reset and wellbeing does not drain; the run holds.
        let later = world.advance(to: noon.adding(hours: 2), .foregroundEnded(at: noon.adding(hours: 1)))
        #expect(later.awayMinutes == 60)
        #expect(later.calmSteps == 3)
    }

    // MARK: - Opens and calm

    @Test func aQuickCheckHalvesAndAChainedOneResets() {
        var world = World()
        let start = noon.adding(hours: -4)
        world.advance(to: noon, .signOfLife(at: start))
        #expect(world.state.calm.tenths == 20)
        let first = gamePass(at: noon, minutes: 3)
        let halved = world.advance(to: noon.adding(minutes: 3), .opened(first))
        #expect(halved.calmHalvings == 1)
        #expect(world.state.calm.tenths == 15)
        let back = noon.adding(minutes: 5)
        let second = gamePass(at: noon.adding(minutes: 10), minutes: 3)
        let reset = world.advance(to: noon.adding(minutes: 13), .returned(at: back), .opened(second))
        #expect(reset.calmResets == 1)
        #expect(world.state.calm.tenths == 10)
    }

    @Test func opensDrainWellbeingAndEscalate() {
        var once = World()
        once.advance(to: noon, .signOfLife(at: noon))
        once.advance(to: noon.adding(minutes: 10), .opened(gamePass(at: noon, minutes: 10)))
        let single = 70 - once.state.care.wellbeing
        #expect(abs(single - (1.5 + 3.5)) < 1e-9)

        var twice = World()
        twice.advance(to: noon, .signOfLife(at: noon))
        twice.advance(to: noon.adding(minutes: 10), .opened(gamePass(at: noon.adding(minutes: -30), minutes: 1)), .opened(gamePass(at: noon, minutes: 10)))
        // The second open's minutes drain ×1.25.
        let second = twice.state.care.wellbeing
        #expect(second < once.state.care.wellbeing - 1.5)
    }

    // MARK: - The breath

    @Test func pastTheDailyHourEveryOpenNeedsABreath() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        var cursor = noon
        for _ in 0..<4 {
            #expect(world.clock.breath(for: world.state, at: cursor) == nil)
            let pass = gamePass(at: cursor, minutes: 15)
            world.advance(to: cursor.adding(minutes: 15), .opened(pass))
            cursor = cursor.adding(minutes: 20)
            world.advance(to: cursor, .signOfLife(at: cursor))
        }
        #expect(world.state.today?.estimatedGuardedMinutes == 60)
        var seconds: [Int?] = []
        for _ in 0..<5 {
            seconds.append(world.clock.breath(for: world.state, at: cursor)?.seconds)
            world.advance(to: cursor.adding(minutes: 3), .opened(gamePass(at: cursor, minutes: 3)))
            cursor = cursor.adding(minutes: 30)
            world.advance(to: cursor, .signOfLife(at: cursor))
        }
        #expect(seconds == [5, 5, 5, 10, 10])
        #expect(world.snapshot.overLimitOpensToday == 5)

        // Local midnight resets the count.
        let tomorrow = instant(2026, 11, 3, 9)
        world.advance(to: tomorrow, .signOfLife(at: tomorrow))
        #expect(world.clock.breath(for: world.state, at: tomorrow) == nil)
    }

    @Test func aMeasuredHourStartsTheBreathWithoutPasses() {
        var world = World(rules: GameRules(measurement: .screenTime))
        world.advance(to: noon, .signOfLife(at: noon), .measured(45, at: noon))
        #expect(world.clock.breath(for: world.state, at: noon) == nil)
        world.advance(to: noon.adding(minutes: 1), .measured(60, at: noon.adding(minutes: 1)))
        #expect(world.clock.breath(for: world.state, at: noon.adding(minutes: 1))?.seconds == 5)
        #expect(world.snapshot.guardedMinutesToday == 60)
    }

    @Test func theEmergencyPassIsNotAnOverLimitOpen() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon), .measured(90, at: noon))
        world.advance(to: noon.adding(minutes: 3), .opened(gamePass(at: noon, minutes: 3, source: .emergency)))
        #expect(world.state.today?.overLimitOpens == 0)
        #expect(world.clock.breath(for: world.state, at: noon, isEmergency: true) == nil)
    }

    // MARK: - Nights

    @Test func aCalmNightHealsAddsCalmAndBringsTheSleepBonus() {
        var world = World()
        let evening = instant(2026, 11, 2, 22)
        world.advance(to: evening, .signOfLife(at: evening))
        let delta = world.advance(to: instant(2026, 11, 3, 7))
        #expect(delta.calmNights == 1)
        #expect(delta.sleepBonusSeeds == 10)
        #expect(world.state.calmNights == 1)
        // 22:00–23:00 grows three steps (×1.3), the night holds the run
        // and adds 0.2, and 06:00–07:00 grows three more.
        #expect(world.state.calm.tenths == 18)
        // 70 + 5 for the quiet hour, + 10 for the calm night (no sleep-off
        // above 60); then one waking hour heals 5 more.
        #expect(abs(world.state.care.wellbeing - 90) < 1e-9)
    }

    @Test func anOpenAtNightSpoilsTheCalmNight() {
        var world = World()
        let evening = instant(2026, 11, 2, 22)
        world.advance(to: evening, .signOfLife(at: evening))
        let late = instant(2026, 11, 3, 1)
        let delta = world.advance(to: instant(2026, 11, 3, 7), .opened(gamePass(at: late, minutes: 10)))
        #expect(delta.calmNights == 0)
        #expect(world.state.calmNights == 0)
        #expect(world.state.calm.tenths == 10)
    }

    @Test func aNightPofuDidNotSeeBeginIsNotACalmNight() {
        var world = World()
        let small = instant(2026, 11, 3, 2)
        world.advance(to: small, .signOfLife(at: small))
        let delta = world.advance(to: instant(2026, 11, 3, 7))
        #expect(delta.calmNights == 0)
    }

    @Test func pofuSleepsOffABadDay() {
        var world = World()
        let evening = instant(2026, 11, 2, 19)
        world.advance(to: evening, .signOfLife(at: evening))
        // A long evening in the feed: three hours, then gone.
        for hour in 0..<3 {
            let start = evening.adding(hours: Double(hour))
            world.advance(to: start.adding(minutes: 60), .opened(gamePass(at: start, minutes: 60)))
        }
        let before = world.state.care.wellbeing
        #expect(before < 25)
        world.advance(to: instant(2026, 11, 3, 6, 30), .returned(at: evening.adding(hours: 3)))
        #expect(world.state.care.wellbeing > before)
        #expect(world.state.care.wellbeing >= 5)
    }

    @Test func theIslandsSleep() {
        var world = World()
        let evening = instant(2026, 11, 2, 18)
        world.advance(to: evening, .signOfLife(at: evening))
        let late = instant(2026, 11, 2, 23, 30)
        world.advance(to: late)
        let result3 = world.collect(at: late)
        #expect(result3 == nil)
        #expect(throws: BuildError.islandsAsleep) { try world.build(.garden, at: late) }
        #expect(world.snapshot.isBedtime)
        let morning = instant(2026, 11, 3, 7)
        let result4 = world.collect(at: morning)
        #expect(result4 != nil)
    }

    // MARK: - Skips

    @Test func skipsHealAndGiftWithinTheirCaps() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        let skips = (0..<8).map { GameEvent.resisted(at: noon.addingTimeInterval(Double($0))) }
        let delta = world.advance(to: noon, applying: skips)
        #expect(delta.resisted == 8)
        #expect(delta.skipSeeds == 15)
        #expect(world.state.care.wellbeing == 76)
    }

    // MARK: - Seeds never touch the gate (A13)

    @Test func seedsNeverBuyTime() throws {
        var poor = World()
        var rich = World()
        rich.state.stations.gather(50_000)
        rich.state.stations.collect()
        for index in 0..<2 {
            var world = index == 0 ? poor : rich
            world.advance(to: noon, .signOfLife(at: noon), .measured(80, at: noon))
            let jar = world.state.stations.jar
            world.advance(
                to: noon.adding(minutes: 30),
                .opened(gamePass(at: noon, minutes: 15, source: .purchased(price: 999))),
                .resisted(at: noon.adding(minutes: 20))
            )
            #expect(world.state.stations.jar == jar)
            if index == 0 { poor = world } else { rich = world }
        }
        let at = noon.adding(minutes: 30)
        #expect(poor.clock.breath(for: poor.state, at: at) == rich.clock.breath(for: rich.state, at: at))
        #expect(poor.clock.breath(for: poor.state, at: at, isRapidReach: true) == rich.clock.breath(for: rich.state, at: at, isRapidReach: true))
        #expect(poor.state.stations.pending == rich.state.stations.pending)
        #expect(poor.state.calm == rich.state.calm)
        #expect(poor.state.care == rich.state.care)
    }

    // MARK: - Tended days, stages, arrivals

    @Test func tendedDaysOpenStagesAndBringIskele() throws {
        var world = World()
        let first = instant(2026, 11, 2, 8)
        world.advance(to: first, .signOfLife(at: first))
        world.state.stations.gather(5_000)
        world.state.stations.collect()
        // Day 1: only the garden's slot is open.
        #expect(throws: BuildError.notOpen(.cay)) { try world.build(.cay, at: first) }
        let second = instant(2026, 11, 3, 8)
        world.advance(to: second, .signOfLife(at: second))
        #expect(world.state.tendedDays == 1)
        #expect(world.snapshot.homeStage == 2)
        for _ in 1...3 {
            try world.build(.cay, at: second)
        }
        var day = second
        for _ in 0..<8 {
            day = day.adding(hours: 24)
            let delta = world.advance(to: day, .signOfLife(at: day))
            if world.state.tendedDays == 8 {
                #expect(delta.arrivals == [.iskele])
            }
        }
        #expect(world.state.tendedDays == 9)
        #expect(world.snapshot.islands == [.aycicegi, .iskele])
        #expect(world.snapshot.stations.contains { $0.id == .simit && $0.isOpen })
    }

    @Test func aDayPofuNeverSawIsNotTended() {
        var world = World()
        world.advance(to: noon, .signOfLife(at: noon))
        // Four days of silence: three observed (the 72-hour window), the
        // fourth not.
        world.advance(to: noon.adding(hours: 24 * 5))
        #expect(world.state.tendedDays == 4)
    }

    // MARK: - Prefix consistency

    @Test(arguments: [UInt64(3), 17, 2_026, 90_210])
    func advancingInStepsEqualsOneAdvance(seed: UInt64) {
        let start = instant(2026, 11, 2, 7, 13, 21)
        let script = randomScript(seed: seed, from: start, hours: 80)
        let end = start.adding(hours: 81)

        var once = World()
        let total = once.advance(to: end, applying: script)

        var stepped = World()
        var sum = WorldDelta()
        var rng = SplitMix64(seed: seed &+ 1)
        var cursor = start
        var remaining = script
        while cursor < end {
            cursor = min(end, cursor.addingTimeInterval(Double(Int.random(in: 1...(5 * 3600), using: &rng))))
            let due = remaining.filter { $0.at <= cursor }
            remaining.removeAll { $0.at <= cursor }
            sum += stepped.advance(to: cursor, applying: due)
        }
        #expect(stepped.state == once.state)
        #expect(sum == total)
    }

    @Test func theStateRoundTripsThroughJSON() throws {
        var world = World()
        let start = instant(2026, 11, 2, 7)
        world.advance(to: start.adding(hours: 40), applying: randomScript(seed: 5, from: start, hours: 40))
        let data = try JSONEncoder().encode(world.state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        #expect(decoded == world.state)
    }

    // MARK: - The gate's event log

    @Test func theGateLogBecomesGameEvents() {
        let pass = gamePass(at: noon, minutes: 5)
        let opened = CheckInRecord(id: UUID(), target: testTarget, attemptedAt: noon, resolvedAt: noon, rung: .pause, outcome: .proceeded(pass))
        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .checkInResolved(opened))) == [.signOfLife(at: noon), .opened(pass)])

        let resisted = CheckInRecord(id: UUID(), target: testTarget, attemptedAt: noon, resolvedAt: noon.adding(minutes: 1), rung: .intent, outcome: .resisted)
        #expect(GameEvent.events(for: resisted) == [.signOfLife(at: noon), .resisted(at: noon.adding(minutes: 1))])

        let passID = UUID()
        let until = noon.adding(minutes: 3)
        let quick = GameEvent.events(for: LoggedEvent(at: noon, event: .quickCheckStarted(passID: passID, target: testTarget, until: until)))
        #expect(quick == [.opened(Pass(id: passID, target: testTarget, grantedAt: noon, expiresAt: until, source: .free(.pause)))])

        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .shieldReachResolved(target: testTarget, resolution: .silentLeave))) == [.resisted(at: noon)])
        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .passEnded(passID: passID, refund: 0))) == [GameEvent(at: noon, kind: .passEndedEarly(passID: passID))])
        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .guardedUsageMeasured(minutes: 30))) == [.measured(30, at: noon)])
        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .shieldShown(target: testTarget, scene: .reach))) == [.signOfLife(at: noon)])
        #expect(GameEvent.events(for: LoggedEvent(at: noon, event: .hopUnavailable(app: .instagram))).isEmpty)
        #expect(GameEvent.event(for: PassThrough(target: testTarget, at: noon, passID: passID)) == .signOfLife(at: noon))
    }
}
