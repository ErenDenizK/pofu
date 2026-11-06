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
        /// The economy brief's typical user: about ten resisted reaches a
        /// day (scale A is sized for this person).
        case typical
        case disciplined
        case relapse
        case monk

        func reachesPerHour(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(3.0, 1.2, Double(day) / 45)
            case .moderate: 1.5
            case .typical: 1.0
            case .disciplined: 0.6
            case .relapse: day < 18 ? lerp(1.6, 1.0, Double(day) / 17) : day < 28 ? 2.6 : lerp(1.6, 1.0, Double(day - 28) / 20)
            case .monk: 0.3
            }
        }

        func resist(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.15, 0.55, Double(day) / 45)
            case .moderate: lerp(0.35, 0.50, Double(day) / 30)
            case .typical: 0.6
            case .disciplined: 0.75
            case .relapse: day < 18 ? lerp(0.40, 0.60, Double(day) / 17) : day < 28 ? 0.15 : lerp(0.40, 0.60, Double(day - 28) / 20)
            case .monk: 1.0
            }
        }

        func carryOn(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.75, 0.40, Double(day) / 45)
            case .moderate: 0.5
            case .typical: 0.4
            case .disciplined: 0.2
            case .relapse: day >= 18 && day < 28 ? 0.80 : 0.45
            case .monk: 0
            }
        }

        func nightSession(_ day: Int) -> Double {
            switch self {
            case .heavy: lerp(0.60, 0.15, Double(day) / 45)
            case .moderate: 0.25
            case .typical: 0.15
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
            case .typical: 0.4
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
            case .typical: 0.15
            case .relapse: 0.3
            case .disciplined, .monk: 0
            }
        }
    }

    /// What the world showed at the end of one simulated day (the flow
    /// audit reads these; the other tests ignore them).
    struct DayLog: Sendable {
        var day: Int
        var tendedDays: Int
        var levels: Int
        var islandLevel: Int
        var harborOpen: Bool
        var kokePhase: WonderStatus.Phase
        var kokeStage: Int
        var caglayanPhase: WonderStatus.Phase
        var caglayanStage: Int
        var hearts: Int
        var decor: Int
        var built: Int
        var seeds: Int
        var resisted: Int
        var wellbeing: Double
    }

    struct Outcome: Sendable {
        var log: [DayLog] = []
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
        /// Koke's timeline (days count from 0): the first day each held.
        var kokeRumourDay: Int?
        var kokeArrivalDay: Int?
        var kokeHealedDay: Int?
        /// Çağlayan's timeline, the same way.
        var caglayanRumourDay: Int?
        var caglayanArrivalDay: Int?
        var caglayanHealedDay: Int?
        var delta = WorldDelta()
        var weekOne = WorldDelta()
        var calmByDay: [Double] = []
        /// Seeds credited each day from every passive source (gathering,
        /// stations, calm nights, skips), before any round is played.
        var seedsByDay: [Int] = Array(repeating: 0, count: GameScenarioTests.days)
        /// Seeds the played rounds paid each day.
        var roundSeedsByDay: [Int] = Array(repeating: 0, count: GameScenarioTests.days)
        /// Resisted reaches each day.
        var resistedByDay: [Int] = Array(repeating: 0, count: GameScenarioTests.days)
        /// Station levels built, at the end of each day.
        var levelsByDay: [Int] = []
        /// Seeds in the jar and pouch at the end of each day.
        var heldByDay: [Int] = []
        /// The island level at the end of each day.
        var islandLevelByDay: [Int] = []
        /// The price of the cheapest level a player could build next (open
        /// and under the cap) at the end of each day; nil when none.
        var cheapestNextCostByDay: [Int?] = []

        func weeksWithoutABuild(weeks: Int) -> Int {
            (0..<weeks).filter { week in !buildDays.contains { $0 / 7 == week } }.count
        }

        /// The mean of `seedsByDay` over `days`.
        func meanSeeds(_ days: Range<Int>) -> Double {
            Double(days.map { seedsByDay[$0] }.reduce(0, +)) / Double(days.count)
        }

        func meanRoundSeeds(_ days: Range<Int>) -> Double {
            Double(days.map { roundSeedsByDay[$0] }.reduce(0, +)) / Double(days.count)
        }

        func meanResisted(_ days: Range<Int>) -> Double {
            Double(days.map { resistedByDay[$0] }.reduce(0, +)) / Double(days.count)
        }

        /// The first day on which `levels` station levels were built.
        func dayReaching(levels: Int) -> Int? {
            levelsByDay.firstIndex { $0 >= levels }
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

    /// The typical user of the economy brief (scale A): the moderate
    /// archetype, who plays five island-game rounds a day.
    static let typical: Outcome = play(.typical, seed: 7, roundsPerVisit: [2, 1, 2])
    static let typicalWithoutRounds: Outcome = outcome(.typical)

    // MARK: - The behavior model (tools/sim/island_economy.py)

    /// - Parameter roundsPerVisit: rounds played at each of the day's three
    ///   visits (as many as are banked), each paying `roundYield` seeds.
    static func play(
        _ archetype: Archetype,
        seed: UInt64,
        measurement: GuardedMeasurement = .softGate,
        roundsPerVisit: [Int] = [0, 0, 0],
        roundYield: Int = 3,
        greetsVisitors: Bool = false
    ) -> Outcome {
        var world = World(rules: GameRules(measurement: measurement))
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
            outcome.seedsByDay[day] += delta.seeds.units
            outcome.resistedByDay[day] += delta.resisted
            if day < 7 {
                outcome.weekOne += delta
            }
            for island in delta.arrivals where outcome.arrivalDay[island] == nil {
                outcome.arrivalDay[island] = day
            }
            outcome.lowestWellbeing = min(outcome.lowestWellbeing, world.state.care.wellbeing)
        }

        let visitMinutes = [120, 420, 870]
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
                if visitMinutes.contains(minuteOfDay), !busy {
                    record(world.advance(to: now, .foregroundBegan(at: now)), day: day)
                    if let visit = visitMinutes.firstIndex(of: minuteOfDay), roundsPerVisit.indices.contains(visit) {
                        for _ in 0..<roundsPerVisit[visit] {
                            guard let paid = try? world.clock.playRound(yield: roundYield, in: &world.state, at: now) else { break }
                            outcome.roundSeedsByDay[day] += paid.units
                        }
                    }
                    _ = world.collect(at: now)
                    if minuteOfDay == 870 {
                        // The evening visit also calls on Koke, once it is there.
                        world.advance(to: now, GameEvent(at: now, kind: .tendedWonder(.koke)))
                        // ... and finishes Çağlayan's flow round, once that is there.
                        world.advance(to: now, GameEvent(at: now, kind: .tendedWonder(.caglayan)))
                        if greetsVisitors {
                            // The evening visit also greets today's visitor,
                            // opens the parcel and helps if asked.
                            world.advance(to: now, GameEvent(at: now, kind: .greetedVisitor))
                            world.advance(to: now, GameEvent(at: now, kind: .openedGift))
                            world.advance(to: now, GameEvent(at: now, kind: .helped))
                        }
                    }
                    var built = 0
                    while built < 2 {
                        let options = world.snapshot.stations.filter { $0.isOpen && $0.nextCost != nil && !$0.isCapped }
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
                // The open's own minute is the first in the feed.
                feedToday += 1
                if Double.random(in: 0..<1, using: &rng) < archetype.carryOn(day) {
                    pendingReach = busyUntil + Int.random(in: 0...3, using: &rng)
                }
            }
            record(world.advance(to: at((day + 1) * 1440)), day: day)
            let koke = world.state.wonders[.koke]
            if koke.rumouredOn != nil { outcome.kokeRumourDay = outcome.kokeRumourDay ?? day }
            if koke.arrivedOn != nil { outcome.kokeArrivalDay = outcome.kokeArrivalDay ?? day }
            if koke.stage >= WonderIslands.healedStage { outcome.kokeHealedDay = outcome.kokeHealedDay ?? day }
            let caglayan = world.state.wonders[.caglayan]
            if caglayan.rumouredOn != nil { outcome.caglayanRumourDay = outcome.caglayanRumourDay ?? day }
            if caglayan.arrivedOn != nil { outcome.caglayanArrivalDay = outcome.caglayanArrivalDay ?? day }
            if caglayan.stage >= WonderIslands.healedStage { outcome.caglayanHealedDay = outcome.caglayanHealedDay ?? day }
            if world.state.care.wellbeing < 25 {
                outcome.unwellDays += 1
            }
            let kokeState = world.state.wonders[.koke]
            outcome.log.append(DayLog(
                day: day,
                tendedDays: world.state.tendedDays,
                levels: world.state.stations.levels.values.reduce(0, +),
                islandLevel: world.snapshot.islandLevel,
                harborOpen: world.state.stations.arrivalOrder.contains(.harbor),
                kokePhase: kokeState.arrivedOn != nil ? .arrived : kokeState.rumouredOn != nil ? .rumoured : .hidden,
                kokeStage: kokeState.stage,
                caglayanPhase: caglayan.arrivedOn != nil ? .arrived : caglayan.rumouredOn != nil ? .rumoured : .hidden,
                caglayanStage: caglayan.stage,
                hearts: world.state.visitors.hearts.values.reduce(0, +),
                decor: world.state.visitors.decor.count,
                built: outcome.buildDays.contains(day) ? 1 : 0,
                seeds: outcome.seedsByDay[day],
                resisted: outcome.resistedByDay[day],
                wellbeing: world.state.care.wellbeing
            ))
            outcome.levelsByDay.append(world.state.stations.levels.values.reduce(0, +))
            outcome.islandLevelByDay.append(world.snapshot.islandLevel)
            outcome.cheapestNextCostByDay.append(
                world.snapshot.stations.filter { $0.isOpen && !$0.isCapped }.compactMap { $0.nextCost?.units }.min()
            )
            outcome.heldByDay.append((world.state.stations.jar + world.state.stations.pending.total).units)
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
        // Seven weeks: after that the quickest have built everything (the
        // full bloom is day 50 or so for the monk) and there is nothing left.
        #expect(outcome.weeksWithoutABuild(weeks: 7) <= 1, "\(archetype): \(outcome.weeksWithoutABuild(weeks: 7)) weeks without a build")
    }

    @Test(arguments: Archetype.allCases)
    func nobodyFinishesTheHomeIslandBeforeAboutDayForty(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        if let done = outcome.homeDoneDay {
            #expect(done >= 35, "\(archetype): home island done on day \(done)")
        }
        // The windmill's slot (island level 8, the 24th tended day) alone
        // holds the line at 24 days.
        #expect((outcome.homeDoneDay ?? Self.days) >= 24)
    }

    @Test(arguments: Archetype.allCases)
    func everyoneGetsTheHarborOnTheThirdDay(archetype: Archetype) {
        // The fog lifts on the third tended day for anyone who builds
        // Mochi's stall, however much they scroll; days here count from 0,
        // and the roll happens at local midnight, hence 1 to 3.
        let outcome = Self.outcome(archetype)
        let harbor = outcome.arrivalDay[.harbor]
        #expect(harbor != nil && (1...3).contains(harbor ?? 99), "\(archetype): Harbor on day \(String(describing: harbor))")
    }

    @Test func kokeFollowsTheTypicalUserFromRumourToHealed() {
        // Rumour about day 5, arrival the next day, healed about day 10
        // (days count from 0, and the roll happens at local midnight).
        let outcome = Self.outcome(.typical)
        let rumour = outcome.kokeRumourDay ?? 99
        #expect((4...8).contains(rumour), "rumour on day \(rumour)")
        #expect(outcome.kokeArrivalDay == rumour + 1)
        let healed = outcome.kokeHealedDay ?? 99
        #expect((rumour + 5...rumour + 8).contains(healed), "healed on day \(healed)")
    }

    @Test func caglayanFollowsKokeForTheTypicalUser() {
        // The rumour only after Koke is healed, the arrival two days later,
        // then one stage a day at most: four stages, so healed at least
        // four days after it arrived.
        let outcome = Self.outcome(.typical)
        let koke = outcome.kokeHealedDay ?? 99
        let rumour = outcome.caglayanRumourDay ?? 99
        #expect(rumour >= koke, "Çağlayan's rumour on day \(rumour), Koke healed on day \(koke)")
        #expect(outcome.caglayanArrivalDay == rumour + WonderIslands.caglayanArrivalDays)
        let healed = outcome.caglayanHealedDay ?? 99
        #expect(healed >= (outcome.caglayanArrivalDay ?? 99) + WonderIslands.healedStage, "healed on day \(healed)")
        #expect(healed <= (outcome.caglayanArrivalDay ?? 99) + 10)
    }

    @Test func kokeStaysGentleForTheLightUserToo() {
        // Even the one who scrolls most only slows Koke down: a skipped
        // day pauses, nothing expires.
        let outcome = Self.outcome(.heavy)
        #expect(outcome.kokeArrivalDay != nil)
        #expect(outcome.kokeHealedDay != nil, "the heavy scroller still heals Koke within 90 days")
        let monk = Self.outcome(.monk)
        #expect((monk.kokeHealedDay ?? 99) <= (monk.kokeArrivalDay ?? 0) + 5)
    }

    @Test(arguments: Archetype.allCases)
    func theIslandLevelNeverFallsAndNeverStallsForLong(archetype: Archetype) {
        let levels = Self.outcome(archetype).islandLevelByDay
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0 <= $1 }, "\(archetype): the island level fell")
        // No dead end: below the top, the next island level comes within
        // three weeks, whoever you are (a skipped day only pauses).
        var longest = 0
        var run = 0
        for (index, level) in levels.enumerated() where level < 10 {
            run = index > 0 && levels[index - 1] == level ? run + 1 : 1
            longest = max(longest, run)
        }
        #expect(longest <= 21, "\(archetype): \(longest) days on one island level")
    }

    @Test(arguments: Archetype.allCases)
    func pofuIsTiredByScrollingNeverGone(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        #expect(outcome.lowestWellbeing >= 5)
        #expect(outcome.longestBreath <= BreathRules.capSeconds)
        #expect(outcome.unwellDays <= 30, "\(archetype): unwell on \(outcome.unwellDays) days")
    }

    // At scale A a skip is +1 seed in a day of 10 to 40 (it was +3 in a day
    // of hundreds), so the old "at most 5 % of week 1" is replaced by the
    // archipelago brief's two limits: at most half of week-1 income for
    // anyone (the cap of six keeps it from being a reason to trigger the
    // gate), and under a quarter once the stations and calm have grown.
    @Test(arguments: Archetype.allCases)
    func skipGiftsStayAThankYou(archetype: Archetype) {
        let outcome = Self.outcome(archetype)
        let total = Double(outcome.weekOne.seeds.units)
        let skips = Double(outcome.weekOne.skipSeeds.units)
        #expect(total > 0)
        #expect(skips / max(total, 1) <= 0.5, "\(archetype): skips are \(skips / max(total, 1) * 100) % of week-1 seeds")
        // Six a day; the simulated day starts at 06:00, so week 1 can touch
        // an eighth local day.
        #expect(skips <= Double(6 * 8), "\(archetype): \(skips) skip seeds in week 1")
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

    // MARK: - Economy scale A: a typical user's 60 days

    // The founder's scale A (2026-11-02): about 10 to 40 seeds a day for a
    // typical user, 15 or so in week 1 rising to 37 or so by day 60, with
    // about ten resisted reaches a day. The typical archetype is that
    // person; the run is the real game model, minute by minute. Round seeds
    // are counted apart (a five-round set is the optional play layer).

    /// The mean seeds a day in each of the first eight weeks.
    static func weeklyMeans(_ outcome: Outcome) -> [Double] {
        (0..<8).map { outcome.meanSeeds(($0 * 7)..<($0 * 7 + 7)) }
    }

    @Test func theTypicalUserResistsAboutTenReachesADay() {
        let resisted = Self.typicalWithoutRounds.meanResisted(0..<60)
        #expect((8.0...14.0).contains(resisted), "resisted reaches a day: \(resisted)")
    }

    @Test func dailyIncomeLandsInTheScaleABands() {
        let outcome = Self.typicalWithoutRounds
        let weeks = Self.weeklyMeans(outcome)
        // Week 1 about 15 (band 12 to 20); day 60 about 37 (band 30 to 42).
        #expect((12.0...20.0).contains(weeks[0]), "week 1: \(weeks[0]) seeds a day")
        #expect((30.0...42.0).contains(outcome.meanSeeds(53..<60)), "days 54 to 60: \(outcome.meanSeeds(53..<60)) seeds a day")
        // Every week sits in the 10 to 40 band for a typical user, and the
        // last week earns well over the first (calm and stations grow).
        #expect(weeks.allSatisfy { (10.0...40.0).contains($0) }, "weekly means \(weeks)")
        #expect(weeks[7] >= weeks[0] * 1.7, "week 8 \(weeks[7]) vs week 1 \(weeks[0])")
        // No single day runs away: gathering (8), skips (6) and a calm night
        // (2) are capped, and the stations are slow.
        #expect(outcome.seedsByDay.prefix(60).allSatisfy { $0 >= 5 && $0 <= 70 }, "days: \(outcome.seedsByDay.prefix(60))")
    }

    @Test func levelPacingFollowsTheIncome() {
        let outcome = Self.typicalWithoutRounds
        // Something is built on day 1; about a level a day in week 1, one
        // every two days later.
        #expect(outcome.firstBuildDay == 0)
        // Home progression section 11.1 (its model is a little slower:
        // 8, 16, 27 and 40 levels on days 7, 14, 30 and 60 with rounds).
        #expect((6...12).contains(outcome.levelsByDay[6]), "levels, day 7: \(outcome.levelsByDay[6])")
        #expect((13...22).contains(outcome.levelsByDay[13]), "levels, day 14: \(outcome.levelsByDay[13])")
        #expect((22...30).contains(outcome.levelsByDay[29]), "levels, day 30: \(outcome.levelsByDay[29])")
        #expect((34...40).contains(outcome.levelsByDay[59]), "levels, day 60: \(outcome.levelsByDay[59])")
        // İskele's fog lifts on the third day (day indices count from 0).
        let harbor = outcome.arrivalDay[.harbor] ?? 99
        #expect((1...3).contains(harbor), "Harbor on day \(harbor)")
        #expect(outcome.weeksWithoutABuild(weeks: 8) == 0)
    }

    @Test func theIslandLevelFollowsTheTable() {
        let levels = Self.typicalWithoutRounds.islandLevelByDay
        // Ada 3 on the third day, Ada 4 inside the first week, Ada 6 by the
        // third week's end, Ada 8 by the second month.
        #expect(levels[2] >= 3, "island level, day 3: \(levels[2])")
        #expect((3...5).contains(levels[6]), "island level, day 7: \(levels[6])")
        #expect((5...7).contains(levels[13]), "island level, day 14: \(levels[13])")
        #expect((6...8).contains(levels[29]), "island level, day 30: \(levels[29])")
        #expect(levels[59] >= 8, "island level, day 60: \(levels[59])")
    }

    @Test func theFullBloomLandsBetweenDayFiftyFiveAndSeventy() throws {
        // Without rounds, the band of home progression section 11.1. With a
        // set of rounds a day it comes about three weeks sooner: decor and
        // the hive (later changes) are the sinks that move it back.
        let plain = try #require(Self.typicalWithoutRounds.islandLevelByDay.firstIndex { $0 == 10 })
        #expect((55...70).contains(plain + 1), "full bloom on day \(plain + 1)")
        let rounds = try #require(Self.typical.islandLevelByDay.firstIndex { $0 == 10 })
        #expect((38...70).contains(rounds + 1), "full bloom with rounds on day \(rounds + 1)")
    }

    @Test(arguments: [Archetype.typical, .moderate, .disciplined])
    func theNextGoalIsAlwaysNearAndSomethingIsNewEveryFewDays(archetype: Archetype) {
        // The cheapest thing a player could build next costs at most three
        // and a half days of the last week's income without rounds (home
        // progression section 3, rule 2: two days, three at the very most,
        // for the income with rounds), and no three days pass without a
        // level (rule 3).
        let outcome = Self.outcome(archetype)
        for day in 7..<60 {
            guard let cost = outcome.cheapestNextCostByDay[day] else { continue }
            let income = Double(outcome.seedsByDay[(day - 6)...day].reduce(0, +)) / 7
            #expect(Double(cost) <= income * 3.5, "\(archetype), day \(day + 1): next goal \(cost) vs \(income) a day")
        }
        let days = outcome.buildDays.sorted().filter { $0 < 60 }
        let gaps = zip(days, days.dropFirst()).map { $1 - $0 }
        #expect((gaps.max() ?? 0) <= 3, "\(archetype): longest stretch without a level is \(gaps.max() ?? 0) days")
    }

    @Test func aSetOfRoundsADayKeepsTheNextGoalNearToo() {
        let outcome = Self.typical
        for day in 7..<60 {
            guard let cost = outcome.cheapestNextCostByDay[day] else { continue }
            let income = Double((day - 6...day).map { outcome.seedsByDay[$0] + outcome.roundSeedsByDay[$0] }.reduce(0, +)) / 7
            #expect(Double(cost) <= income * 3, "day \(day + 1): next goal \(cost) vs \(income) a day")
        }
    }

    @Test func skipsAreUnderAQuarterOfIncomeFromWeekTwo() {
        let outcome = Self.typicalWithoutRounds
        let skips = outcome.delta.skipSeeds.units - outcome.weekOne.skipSeeds.units
        let total = outcome.delta.seeds.units - outcome.weekOne.seeds.units
        #expect(Double(skips) / Double(total) <= 0.25, "skips are \(Double(skips) / Double(total) * 100) % of income from week 2")
    }

    @Test func aFiveRoundSetAddsAboutFifteenSeedsAndNeverBreaksTheCaps() {
        let outcome = Self.typical
        let rounds = outcome.meanRoundSeeds(0..<60)
        // Five rounds at 3 seeds (the yield ladder pays 2 to 5).
        #expect((12.0...16.0).contains(rounds), "round seeds a day: \(rounds)")
        #expect(outcome.roundSeedsByDay.prefix(60).allSatisfy { $0 <= 12 * 5 })
        // With a set a day, a typical day stays under 65 seeds in total.
        let total = outcome.meanSeeds(53..<60) + outcome.meanRoundSeeds(53..<60)
        #expect(total <= 65, "days 54 to 60 with a set a day: \(total) seeds")
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
