import Foundation
import Testing
@testable import PofuCore

/// The archetypes of `tools/sim/island_economy.py`, played through the
/// real game model for 90 days with honest inputs:
///
/// - the model sees only what Pofu can measure: reaches, skips, passes
///   and their early ends, and Pofu's own foreground time;
/// - under the soft gate, some users keep scrolling after a pass expires,
///   and the model never hears of it (decision audit C1);
/// - there is no friend: the fourth rapid reach falls back to the breath
///   (ADR-0015 amendment), and the breath's effect is the simulation's
///   assumption (20 % of breathed opens end in a skip);
/// - builds happen in three short visits a day, cheapest open level first,
///   at most two a visit.
///
/// The tests check the simulation's targets, not its exact numbers: the
/// behavior model is a mirror, not a port.
@Suite("Game scenarios")
struct GameScenarioTests {
    enum Archetype: String, CaseIterable, Sendable {
        case heavy
        case moderate
        case disciplined
        case relapse
        case monk

        func reachesPerHour(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(3.0, 1.2, Double(day) / 45)
            case .moderate: 1.5
            case .disciplined: 0.6
            case .relapse: day < 18 ? lerp(1.6, 1.0, Double(day) / 17) : day < 28 ? 2.6 : lerp(1.6, 1.0, Double(day - 28) / 20)
            case .monk: 0.3
            }
        }

        func resist(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.15, 0.55, Double(day) / 45)
            case .moderate: lerp(0.35, 0.50, Double(day) / 30)
            case .disciplined: 0.75
            case .relapse: day < 18 ? lerp(0.40, 0.60, Double(day) / 17) : day < 28 ? 0.15 : lerp(0.40, 0.60, Double(day - 28) / 20)
            case .monk: 1.0
            }
        }

        func carryOn(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.75, 0.40, Double(day) / 45)
            case .moderate: 0.5
            case .disciplined: 0.2
            case .relapse: day >= 18 && day < 28 ? 0.80 : 0.45
            case .monk: 0
            }
        }

        func nightSession(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.60, 0.15, Double(day) / 45)
            case .moderate: 0.25
            case .disciplined: 0.05
            case .relapse: day >= 18 && day < 28 ? 0.65 : 0.2
            case .monk: 0
            }
        }

        var openMinutes: Int {
            self == .disciplined || self == .monk ? 10 : 15
        }

        var quickShare: Double {
            switch self {
            case .heavy: 0.2
            case .moderate: 0.35
            case .disciplined: 0.6
            case .relapse: 0.3
            case .monk: 0
            }
        }

        var endEarly: Double {
            switch self {
            case .disciplined: 0.3
            case .monk: 0
            default: 0.1
            }
        }

        /// The honest input the simulation lacked: the share of passes the
        /// user scrolls past without telling Pofu.
        var overstay: Double {
            switch self {
            case .heavy: 0.4
            case .moderate: 0.25
            case .relapse: 0.3
            case .disciplined, .monk: 0
            }
        }
    }

    struct Outcome: Sendable {
        var firstBuildDay: Int?
        var homeDoneDay: Int?
        var arrivalDay: [IslandID: Int] = [:]
        var buildDays: Set<Int> = []
        var lowestWellbeing = 100.0
        var unwellDays = 0
        /// Minutes truly spent in guarded apps, overstay included.
        var trueFeedMinutes = 0
        var trueFeedByDay: [Int] = []
        var breathsByDay: [Int] = []
        var breathSeconds = 0
        var longestBreath = 0
        var delta = WorldDelta()
        var weekOne = WorldDelta()
        var calmByDay: [Double] = []

        func weeksWithoutABuild(weeks: Int) -> Int {
            (0..<weeks).filter { week in !buildDays.contains { $0 / 7 == week } }.count
        }

        var weekOneSeedsPerDay: Double {
            Double(weekOne.seeds.units) / 7
        }
    }

    static let days = 90
    static let start = instant(2026, 11, 2, 6)

    /// One 90-day run per archetype, shared by the tests (each run walks
    /// 129,600 minutes).
    static let outcomes: [Archetype: Outcome] = Dictionary(
        uniqueKeysWithValues: Archetype.allCases.map { ($0, play($0, seed: 7)) }
    )

    static func outcome(_ archetype: Archetype) -> Outcome {
        outcomes[archetype] ?? play(archetype, seed: 7)
    }

    // MARK: - The behavior model (tools/sim/island_economy.py)

    static func play(_ archetype: Archetype, seed: UInt64, measurement: GuardedMeasurement = .softGate) -> Outcome {
        var world = World(rules: GameRules(measurement: measurement, releasedIslands: [.kitap]))
        var rng = SplitMix64(seed: seed)
        var outcome = Outcome()
        var busyUntil = -1
        var pendingReach: Int?
        var lastAttempt = -10_000
        var rung = 0
        let homeStations = world.rules.catalog.stations(on: world.rules.catalog.home).map(\.id)

        func at(_ minute: Int) -> Date {
            start.addingTimeInterval(Double(minute) * 60)
        }
        func record(_ delta: WorldDelta, day: Int) {
            outcome.delta += delta
            if day < 7 {
                outcome.weekOne += delta
            }
            for island in delta.arrivals where outcome.arrivalDay[island] == nil {
                outcome.arrivalDay[island] = day
            }
            outcome.lowestWellbeing = min(outcome.lowestWellbeing, world.state.care.wellbeing)
        }

        world.advance(to: start, .signOfLife(at: start))
        for day in 0..<days {
            let reachChance = archetype.reachesPerHour(day) / 60
            let resist = archetype.resist(day)
            let nightSession = Double.random(in: 0..<1, using: &rng) < archetype.nightSession(day)
            let nightAt = nightSession ? Int.random(in: (17 * 60 + 5)...(18 * 60 + 30), using: &rng) : nil
            var feedToday = 0
            var breathsToday = 0
            var calmSum = 0.0
            var calmSamples = 0

            for minuteOfDay in 0..<1440 {
                let minute = day * 1440 + minuteOfDay
                let now = at(minute)
                let bedtime = minuteOfDay >= 17 * 60
                let awake = minuteOfDay >= 60 && minuteOfDay < 17 * 60
                let busy = busyUntil > minute

                if minuteOfDay % 60 == 0, !bedtime {
                    record(world.advance(to: now), day: day)
                    calmSum += world.state.calm.multiplier
                    calmSamples += 1
                }

                // Three short visits: collect, build, leave.
                if minuteOfDay == 120 || minuteOfDay == 420 || minuteOfDay == 870, !busy {
                    record(world.advance(to: now, .foregroundBegan(at: now)), day: day)
                    _ = world.collect(at: now)
                    var built = 0
                    while built < 2 {
                        let options = world.snapshot.stations.filter { $0.isOpen && $0.nextCost != nil }
                        guard let cheapest = options.min(by: { ($0.nextCost ?? 0) < ($1.nextCost ?? 0) }), cheapest.canAfford else { break }
                        do {
                            try world.build(cheapest.id, at: now)
                        } catch {
                            Issue.record("Build failed: \(error)")
                            break
                        }
                        built += 1
                        outcome.firstBuildDay = outcome.firstBuildDay ?? day
                        outcome.buildDays.insert(day)
                    }
                    if outcome.homeDoneDay == nil, homeStations.allSatisfy({ world.state.stations.level(of: $0) == 5 }) {
                        outcome.homeDoneDay = day
                    }
                    record(world.advance(to: at(minute + 1), .foregroundEnded(at: at(minute + 1))), day: day)
                    // The visit took the minute.
                    continue
                }

                guard !busy else {
                    feedToday += 1
                    continue
                }
                var reach = false
                if let due = pendingReach, minute >= due {
                    reach = true
                    pendingReach = nil
                } else if awake, !bedtime, Double.random(in: 0..<1, using: &rng) < reachChance {
                    reach = true
                } else if minuteOfDay == nightAt {
                    reach = true
                }
                guard reach else { continue }

                rung = minute - lastAttempt < 60 ? min(rung + 1, 3) : 0
                lastAttempt = minute
                var resistChance = resist + (rung >= 2 ? 0.15 : 0)
                if bedtime {
                    resistChance = min(resistChance, 0.3)
                }
                record(world.advance(to: now), day: day)
                if Double.random(in: 0..<1, using: &rng) < resistChance {
                    record(world.advance(to: now, .resisted(at: now)), day: day)
                    continue
                }
                let quick = Double.random(in: 0..<1, using: &rng) < archetype.quickShare
                let minutes = quick ? 3 : rung < 2 ? 5 : archetype.openMinutes
                if let breath = world.clock.breath(for: world.state, at: now, isRapidReach: rung == 3) {
                    breathsToday += 1
                    outcome.breathSeconds += breath.seconds
                    outcome.longestBreath = max(outcome.longestBreath, breath.seconds)
                    if Double.random(in: 0..<1, using: &rng) < 0.2 {
                        record(world.advance(to: now, .resisted(at: now)), day: day)
                        continue
                    }
                }
                let pass = Pass(target: testTarget, grantedAt: now, minutes: minutes, source: .free(.pause))
                var events: [GameEvent] = [.opened(pass)]
                var trueMinutes = minutes
                if Double.random(in: 0..<1, using: &rng) < archetype.endEarly {
                    trueMinutes = max(1, minutes / 3)
                    events.append(.endedEarly(pass, at: at(minute + trueMinutes)))
                } else if measurement == .softGate, Double.random(in: 0..<1, using: &rng) < archetype.overstay {
                    // Scrolls on past the expiry; nothing tells Pofu.
                    trueMinutes += Int.random(in: 5...40, using: &rng)
                }
                record(world.advance(to: now, applying: events), day: day)
                busyUntil = minute + trueMinutes
                if Double.random(in: 0..<1, using: &rng) < archetype.carryOn(day) {
                    pendingReach = busyUntil + Int.random(in: 0...3, using: &rng)
                }
            }
            record(world.advance(to: at((day + 1) * 1440)), day: day)
            if world.state.care.wellbeing < 25 {
                outcome.unwellDays += 1
            }
            outcome.trueFeedMinutes += feedToday
            outcome.trueFeedByDay.append(feedToday)
            outcome.breathsByDay.append(breathsToday)
            outcome.calmByDay.append(calmSum / Double(max(1, calmSamples)))
        }
        return outcome
    }

    // MARK: - The simulation's targets

    @Test(arguments: Archetype.allCases)
    func everyoneBuildsOnDayOneAndKeepsBuilding(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        #expect(outcome.firstBuildDay == 0, "\(archetype): first build on day \(String(describing: outcome.firstBuildDay))")
        #expect(outcome.weeksWithoutABuild(weeks: 12) <= 1, "\(archetype): \(outcome.weeksWithoutABuild(weeks: 12)) weeks without a build")
    }

    @Test(arguments: Archetype.allCases)
    func nobodyFinishesTheHomeIslandBeforeAboutDayForty(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        if let done = outcome.homeDoneDay {
            #expect(done >= 35, "\(archetype): home island done on day \(done)")
        }
        // The windmill's stage-5 gate alone holds the line at 24 tended
        // days.
        #expect((outcome.homeDoneDay ?? Self.days) >= 24)
    }

    @Test(arguments: Archetype.allCases)
    func heavyScrollersStillGetASecondIslandWithinTheMonth(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        let iskele = outcome.arrivalDay[.iskele]
        #expect(iskele != nil && (iskele ?? 99) <= 30, "\(archetype): İskele on day \(String(describing: iskele))")
        // Arrivals are kind: tended days and calm nights are cumulative.
        #expect(outcome.arrivalDay[.yildiz] != nil || archetype == .heavy || archetype == .relapse,
                "\(archetype): Yıldız never arrived")
    }

    @Test(arguments: Archetype.allCases)
    func pofuIsTiredByScrollingNeverGone(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        #expect(outcome.lowestWellbeing >= 5)
        #expect(outcome.longestBreath <= BreathRules.capSeconds)
        #expect(outcome.unwellDays <= 30, "\(archetype): unwell on \(outcome.unwellDays) days")
    }

    @Test(arguments: Archetype.allCases)
    func skipGiftsStayAThankYou(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        let total = Double(outcome.weekOne.seeds.units)
        let skips = Double(outcome.weekOne.skipSeeds.units)
        #expect(total > 0)
        #expect(skips / max(total, 1) <= 0.05, "\(archetype): skips are \(skips / max(total, 1) * 100) % of week-1 seeds")
    }

    @Test func scrollingVisiblySlowsTheWorld() {
        let heavy = Self.outcome(.heavy)
        let disciplined = Self.outcome(.disciplined)
        let monk = Self.outcome(.monk)
        #expect(heavy.weekOneSeedsPerDay < disciplined.weekOneSeedsPerDay,
                "heavy \(heavy.weekOneSeedsPerDay) vs disciplined \(disciplined.weekOneSeedsPerDay) seeds a day")
        #expect(disciplined.weekOneSeedsPerDay <= monk.weekOneSeedsPerDay * 1.05)
        let heavyCalm = heavy.calmByDay.prefix(7).reduce(0, +) / 7
        let monkCalm = monk.calmByDay.prefix(7).reduce(0, +) / 7
        #expect(heavyCalm < monkCalm, "calm week 1: heavy \(heavyCalm), monk \(monkCalm)")
        // Wellbeing is the louder signal.
        #expect(heavy.lowestWellbeing < disciplined.lowestWellbeing)
    }

    @Test func theHeavyScrollerMeetsTheBreathAndItFades() {
        let heavy = Self.outcome(.heavy)
        let weekOne = Double(heavy.breathsByDay.prefix(7).reduce(0, +)) / 7
        let weekThirteen = Double(heavy.breathsByDay.suffix(7).reduce(0, +)) / 7
        #expect(weekOne > 1, "breaths a day, week 1: \(weekOne)")
        #expect(weekThirteen < weekOne, "breaths a day, week 13: \(weekThirteen) vs week 1: \(weekOne)")
    }

    // MARK: - Honesty (decision audit C1)

    @Test(arguments: [Archetype.heavy, .moderate, .relapse])
    func scrollingPastAnExpiryNeverCountsAsAway(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        let delta = outcome.delta
        let processed = delta.awayMinutes + delta.guardedMinutes + delta.pausedMinutes + delta.unobservedMinutes
        #expect(processed >= Self.days * 1440)
        // Every truly scrolled minute is either a pass the model knows of
        // or time it treats as unobserved: none of it counts as away.
        #expect(delta.guardedMinutes + delta.unobservedMinutes >= outcome.trueFeedMinutes,
                "\(archetype): guarded \(delta.guardedMinutes) + unobserved \(delta.unobservedMinutes) < true feed \(outcome.trueFeedMinutes)")
        #expect(delta.awayMinutes <= processed - outcome.trueFeedMinutes)
        // And the soft gate really did miss some scrolling.
        #expect(delta.guardedMinutes < outcome.trueFeedMinutes)
    }

    @Test func withScreenTimeTheShieldEndsEveryPass() {
        let outcome = Self.play(.heavy, seed: 7, measurement: .screenTime)
        #expect(outcome.delta.unobservedMinutes == 0)
        // Equal but for a pass still running when the run ends.
        #expect(abs(outcome.delta.guardedMinutes - outcome.trueFeedMinutes) <= 40,
                "guarded \(outcome.delta.guardedMinutes) vs true feed \(outcome.trueFeedMinutes)")
    }
}

/// The simulation's linear ramp, clamped to its ends.
private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * min(max(t, 0), 1)
}
