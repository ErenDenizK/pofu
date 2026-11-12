import Foundation
import Testing
@testable import PofuCore

/// The demo run (game-solid spec, PR 1): days 1 to 21 played the way the
/// demo is played, in Rehearsal mode, for the typical and the heavy player
/// (through `GameScenarioTests.play`, saving and loading the game at every
/// visit) and for the tester (the Prova panel's own path: one reach a day,
/// then "Next day", written here with no behaviour model).
///
/// What `FlowAuditTests` does not check, this does: a save round-trip at
/// every visit, seeds that only ever build levels (ADR-0015), a next goal
/// that stays near, an on-screen change count that leaves decor out (no
/// decor spot exists yet), and the "Next day"-only path.
///
/// Days count from 0 in the code and from 1 in the messages. Each run
/// prints one line per day so the pacing can be read in CI logs.
@Suite("Demo run, days 1 to 21")
struct DemoRunTests {
    enum Player: String, CaseIterable, Sendable {
        case typical
        case heavy

        var archetype: GameScenarioTests.Archetype {
            switch self {
            case .typical: .typical
            case .heavy: .heavy
            }
        }

        var roundsPerVisit: [Int] {
            switch self {
            case .typical: [2, 1, 2]
            case .heavy: [1, 0, 1]
            }
        }
    }

    static let horizon = 21

    struct RunKey: Hashable, Sendable {
        var player: Player
        var relaunch: Bool
    }

    static let runs: [RunKey: GameScenarioTests.Outcome] = Dictionary(
        uniqueKeysWithValues: Player.allCases.flatMap { player in
            [false, true].map { relaunch in
                (
                    RunKey(player: player, relaunch: relaunch),
                    GameScenarioTests.play(
                        player.archetype,
                        seed: 7,
                        roundsPerVisit: player.roundsPerVisit,
                        greetsVisitors: true,
                        relaunch: relaunch,
                        horizon: horizon
                    )
                )
            }
        }
    )

    static func outcome(_ player: Player, relaunch: Bool = true) -> GameScenarioTests.Outcome {
        runs[RunKey(player: player, relaunch: relaunch)] ?? GameScenarioTests.Outcome()
    }

    static func log(_ player: Player, relaunch: Bool = true) -> [GameScenarioTests.DayLog] {
        outcome(player, relaunch: relaunch).log
    }

    // MARK: - What is on screen

    /// What is new on `index` compared with the day before, as the player
    /// sees it. Decor is left out: nothing can place a decor piece yet.
    static func changes(_ log: [GameScenarioTests.DayLog], at index: Int) -> [String] {
        let now = log[index]
        let before = index > 0 ? log[index - 1] : nil
        var found: [String] = []
        if now.levels > (before?.levels ?? 0) { found.append("+\(now.levels - (before?.levels ?? 0)) lvl") }
        if now.islandLevel > (before?.islandLevel ?? 0) { found.append("IL\(now.islandLevel)") }
        if now.harborOpen, !(before?.harborOpen ?? false) { found.append("harbor") }
        if now.kokePhase.rawValue > (before?.kokePhase ?? .hidden).rawValue {
            found.append(now.kokePhase == .rumoured ? "Koke rumour" : "Koke arrives")
        }
        if now.kokeStage > (before?.kokeStage ?? 0) { found.append("Koke stage \(now.kokeStage)") }
        if now.caglayanPhase.rawValue > (before?.caglayanPhase ?? .hidden).rawValue {
            found.append(now.caglayanPhase == .rumoured ? "Çağlayan rumour" : "Çağlayan arrives")
        }
        if now.caglayanStage > (before?.caglayanStage ?? 0) { found.append("Çağlayan stage \(now.caglayanStage)") }
        if now.hearts > (before?.hearts ?? 0) { found.append("heart \(now.hearts)") }
        return found
    }

    /// Start days (1-based) of every window of three days with nothing new.
    static func deadWindows(_ log: [GameScenarioTests.DayLog]) -> [ClosedRange<Int>] {
        guard log.count >= 3 else { return [] }
        let changed = log.indices.map { !changes(log, at: $0).isEmpty }
        return (0...(log.count - 3)).compactMap { start in
            changed[start..<(start + 3)].contains(true) ? nil : (start + 1)...(start + 3)
        }
    }

    /// The compact day-by-day log (the format of `FlowAuditTests.render`,
    /// with the jar added).
    static func render(_ player: Player) -> String {
        let log = log(player)
        var lines = ["DEMO RUN \(player.rawValue)"]
        for index in log.indices {
            let day = log[index]
            let new = changes(log, at: index)
            lines.append(
                "  d\(String(format: "%02d", index + 1)) tended \(String(format: "%2d", day.tendedDays))"
                    + " seeds \(String(format: "%3d", day.seeds)) resisted \(String(format: "%2d", day.resisted))"
                    + " jar \(String(format: "%3d", day.jarEnd))"
                    + " levels \(String(format: "%2d", day.levels)) IL\(String(format: "%2d", day.islandLevel))"
                    + " hearts \(day.hearts) koke \(day.kokePhase)/\(day.kokeStage)"
                    + " caglayan \(day.caglayanPhase)/\(day.caglayanStage)"
                    + " well \(String(format: "%3.0f", day.wellbeing))"
                    + (new.isEmpty ? "  . (nothing new)" : "  NEW: " + new.joined(separator: ", "))
            )
        }
        return lines.joined(separator: "\n")
    }

    /// The 1-based day a wonder island was first healed, if it was.
    static func healedDay(_ log: [GameScenarioTests.DayLog], stage: KeyPath<GameScenarioTests.DayLog, Int>) -> Int? {
        log.firstIndex { $0[keyPath: stage] >= WonderIslands.healedStage }.map { $0 + 1 }
    }

    // MARK: - The typical and the heavy player

    @Test(arguments: Player.allCases)
    func printsTheDayByDayLog(player: Player) {
        #expect(Self.log(player).count == Self.horizon)
        print(Self.render(player))
    }

    @Test(arguments: Player.allCases)
    func everyDayIsTended(player: Player) {
        for (index, day) in Self.log(player).enumerated() {
            #expect(day.tendedDays == index + 1, "\(player): \(day.tendedDays) tended days at the end of day \(index + 1)")
        }
    }

    @Test(arguments: Player.allCases)
    func aSaveSurvivesEveryRelaunch(player: Player) {
        let relaunched = Self.outcome(player, relaunch: true)
        let straight = Self.outcome(player, relaunch: false)
        #expect(relaunched.relaunchMismatches == 0, "\(player): \(relaunched.relaunchMismatches) visits changed the game")
        #expect(straight.relaunchMismatches == 0)
        #expect(relaunched.log.count == Self.horizon)
        #expect(relaunched.log == straight.log, "\(player): playing across relaunches differs from playing straight through")
    }

    @Test(arguments: Player.allCases)
    func somethingNewOnScreenEveryThreeDays(player: Player) {
        let log = Self.log(player)
        let dead = Self.deadWindows(log).map { "days \($0.lowerBound) to \($0.upperBound)" }
        #expect(dead.isEmpty, "\(player): windows of three days with nothing new (decor does not count): \(dead.joined(separator: "; "))\n\(Self.render(player))")
    }

    @Test(arguments: Player.allCases)
    func theNextGoalIsAlwaysNear(player: Player) {
        let outcome = Self.outcome(player)
        let log = outcome.log
        for index in 3..<log.count {
            let income = Double((index - 3..<index).map { outcome.seedsByDay[$0] + outcome.roundSeedsByDay[$0] }.reduce(0, +)) / 3
            let day = log[index]
            if let cost = day.cheapestNextCost {
                #expect(Double(cost) <= 3 * income, "\(player), day \(index + 1): next goal costs \(cost), the last three days brought \(income) a day")
            } else {
                // Nothing is open under the cap: the island level is the goal.
                #expect((day.nextDaysLeft ?? 0) <= 3, "\(player), day \(index + 1): nothing to build and the next island level is \(day.nextDaysLeft ?? 0) tended days away")
            }
        }
    }

    @Test(arguments: Player.allCases)
    func kokeAndCaglayanAreFinishable(player: Player) {
        let log = Self.log(player)
        let koke = Self.healedDay(log, stage: \.kokeStage)
        let caglayan = Self.healedDay(log, stage: \.caglayanStage)
        let limits = player == .typical ? (koke: 11, caglayan: 18) : (koke: 13, caglayan: 21)
        #expect((koke ?? 99) <= limits.koke, "\(player): Koke healed on day \(koke.map(String.init) ?? "never"), limit \(limits.koke)")
        #expect((caglayan ?? 99) <= limits.caglayan, "\(player): Çağlayan healed on day \(caglayan.map(String.init) ?? "never"), limit \(limits.caglayan)")
    }

    @Test(arguments: Player.allCases)
    func seedsOnlyEverBuildLevels(player: Player) {
        // The jar changes in two ways only: a collection fills it and a
        // build empties it. No seed is ever turned into minutes (ADR-0015).
        var jarBefore = 0
        for day in Self.log(player) {
            #expect(
                day.jarEnd == jarBefore + day.collected - day.spent,
                "\(player), day \(day.day + 1): jar \(jarBefore) -> \(day.jarEnd), collected \(day.collected), spent \(day.spent)"
            )
            #expect(day.jarEnd >= 0)
            jarBefore = day.jarEnd
        }
    }

    @Test(arguments: Player.allCases)
    func pofuNeverDies(player: Player) {
        let floor = CareRules().floor
        for day in Self.log(player) {
            #expect(day.lowestWellbeing >= floor, "\(player), day \(day.day + 1): wellbeing \(day.lowestWellbeing)")
        }
    }

    // MARK: - The tester: the Prova panel's own path

    /// What the tester sees at the end of one visit.
    struct Visit: Sendable, Equatable {
        var day: Int
        var tendedDays: Int
        var harborOpen: Bool
        var levels: Int
        var islandLevel: Int
        var kokeStage: Int
        var caglayanStage: Int
        var jar: Int
    }

    /// The Prova panel's moves, one day at a time, with no behaviour model.
    ///
    /// Day 1 starts at 09:00 local with a sign of life and Pofu in the
    /// foreground. Each day: `reaches` resisted reaches from 09:01, collect
    /// at 09:05 and build up to two of the cheapest open, uncapped,
    /// affordable levels, every banked garden round at yield 3, the wonders
    /// and the visitor at 09:07, leave at 09:10. "Next day" then lands on
    /// the next 09:00, the time away told to the game as the panel tells it.
    ///
    /// - Returns: The visits, the world as it was left at the last visit,
    ///   the time of the next day's start and the events that tell the game
    ///   about the time away before it.
    static func tester(days: Int = horizon, reaches: (Int) -> Int) -> (visits: [Visit], world: World, next: Date, arrival: [GameEvent]) {
        var world = World(rules: GameRules(), calendar: .istanbul)
        let time = RehearsalTime(bedtime: world.rules.bedtime, calendar: .istanbul)
        var visits: [Visit] = []
        var start = instant(2026, 11, 2, 9)
        var arrival: [GameEvent] = [.signOfLife(at: start), .foregroundBegan(at: start)]
        var next = start
        for day in 1...days {
            world.advance(to: start, applying: arrival)
            var events: [GameEvent] = []
            for reach in 0..<reaches(day) {
                let at = start.adding(minutes: Double(1 + 2 * reach))
                events.append(.signOfLife(at: at))
                events.append(.resisted(at: at.adding(minutes: 1)))
            }
            let collectAt = start.adding(minutes: 5)
            world.advance(to: collectAt, applying: events)
            _ = world.collect(at: collectAt)
            var built = 0
            while built < 2 {
                let options = world.snapshot.stations.filter { $0.isOpen && $0.nextCost != nil && !$0.isCapped }
                guard let cheapest = options.min(by: { ($0.nextCost ?? 0) < ($1.nextCost ?? 0) }), cheapest.canAfford else { break }
                do {
                    try world.build(cheapest.id, at: collectAt)
                } catch {
                    Issue.record("Build failed: \(error)")
                    break
                }
                built += 1
            }
            let roundsAt = start.adding(minutes: 6)
            world.advance(to: roundsAt)
            for _ in 0..<world.clock.playableRounds(in: world.state, at: roundsAt) {
                do {
                    try world.clock.playRound(yield: 3, in: &world.state, at: roundsAt)
                } catch {
                    Issue.record("Round failed: \(error)")
                    break
                }
            }
            let tendAt = start.adding(minutes: 7)
            world.advance(to: tendAt, applying: [
                GameEvent(at: tendAt, kind: .tendedWonder(.koke)),
                GameEvent(at: tendAt, kind: .tendedWonder(.caglayan)),
                GameEvent(at: tendAt, kind: .greetedVisitor),
                GameEvent(at: tendAt, kind: .openedGift),
                GameEvent(at: tendAt, kind: .helped),
            ])
            let leave = start.adding(minutes: 10)
            world.advance(to: leave)
            visits.append(Visit(
                day: day,
                tendedDays: world.state.tendedDays,
                harborOpen: world.state.stations.arrivalOrder.contains(.harbor),
                levels: world.state.stations.levels.values.reduce(0, +),
                islandLevel: world.snapshot.islandLevel,
                kokeStage: world.state.wonders[.koke].stage,
                caglayanStage: world.state.wonders[.caglayan].stage,
                jar: world.state.stations.jar.units
            ))
            next = time.destination(of: .nextDay, from: leave)
            arrival = RehearsalTime.awayEvents(leaving: leave, returning: next)
            start = next
        }
        return (visits, world, next, arrival)
    }

    static let testerVisits = tester { _ in 1 }.visits
    static let nextDayOnlyVisits = tester { $0 == 1 ? 1 : 0 }.visits

    @Test func printsTheTestersDays() {
        #expect(Self.testerVisits.count == Self.horizon)
        var lines = ["DEMO RUN tester"]
        for visit in Self.testerVisits {
            lines.append(
                "  d\(String(format: "%02d", visit.day)) tended \(String(format: "%2d", visit.tendedDays))"
                    + " jar \(String(format: "%3d", visit.jar)) levels \(String(format: "%2d", visit.levels))"
                    + " IL\(String(format: "%2d", visit.islandLevel)) harbor \(visit.harborOpen)"
                    + " koke \(visit.kokeStage) caglayan \(visit.caglayanStage)"
            )
        }
        print(lines.joined(separator: "\n"))
        var pausedLines = ["DEMO RUN nextDayOnly"]
        for visit in Self.nextDayOnlyVisits {
            pausedLines.append(
                "  d\(String(format: "%02d", visit.day)) tended \(String(format: "%2d", visit.tendedDays))"
                    + " jar \(String(format: "%3d", visit.jar)) levels \(String(format: "%2d", visit.levels))"
                    + " IL\(String(format: "%2d", visit.islandLevel)) harbor \(visit.harborOpen)"
                    + " koke \(visit.kokeStage) caglayan \(visit.caglayanStage)"
            )
        }
        print(pausedLines.joined(separator: "\n"))
    }

    @Test func testerSeesTheHarborOnDayThree() {
        let visits = Self.testerVisits
        #expect(!visits[1].harborOpen, "the harbor is open at day 2's visit")
        #expect(visits[2].harborOpen, "the harbor is not open at day 3's visit")
    }

    @Test func testerHealsKokeByDayTen() {
        let visits = Self.testerVisits
        #expect(visits[9].kokeStage >= WonderIslands.healedStage, "Koke is at stage \(visits[9].kokeStage) at day 10's visit")
    }

    @Test func testerHealsCaglayanByDaySixteen() {
        let visits = Self.testerVisits
        #expect(visits[15].caglayanStage >= WonderIslands.healedStage, "Çağlayan is at stage \(visits[15].caglayanStage) at day 16's visit")
    }

    @Test func testerTendsEveryDay() {
        for visit in Self.testerVisits {
            #expect(visit.tendedDays == visit.day - 1, "day \(visit.day): \(visit.tendedDays) tended days")
        }
    }

    @Test func nextDayOnlyTesterPausesWithoutLoss() {
        // G12: with no reach after day 1, "Next day" alone lets the 72-hour
        // observation window run out. The world pauses; it takes nothing back.
        let visits = Self.nextDayOnlyVisits
        #expect(visits.count == Self.horizon)
        let paused = visits[4].tendedDays
        for visit in visits where visit.day >= 5 {
            #expect(visit.tendedDays == paused, "day \(visit.day): tended days still moved (\(visit.tendedDays), not \(paused))")
        }
        for (earlier, later) in zip(visits, visits.dropFirst()) {
            #expect(later.tendedDays >= earlier.tendedDays, "day \(later.day): tended days fell")
            #expect(later.levels >= earlier.levels, "day \(later.day): station levels fell")
            #expect(later.islandLevel >= earlier.islandLevel, "day \(later.day): the island level fell")
            #expect(later.kokeStage >= earlier.kokeStage, "day \(later.day): Koke's stage fell")
            #expect(later.caglayanStage >= earlier.caglayanStage, "day \(later.day): Çağlayan's stage fell")
            #expect(!earlier.harborOpen || later.harborOpen, "day \(later.day): the harbor closed")
        }
    }

    // MARK: - Island arrival without Koke and the islands asleep (PR 2)

    @Test
    func caglayanComesAtTendedDayTwelveWhenKokeIsIgnored() throws {
        // D4: Koke is never tapped, a reach is resisted every day.
        let outcome = GameScenarioTests.play(
            .typical, seed: 7, greetsVisitors: true, horizon: Self.horizon, tapsKoke: false
        )
        let log = outcome.log
        let rumour = try #require(log.firstIndex { $0.caglayanPhase != .hidden }, "Çağlayan never came while Koke was ignored")
        #expect(log[rumour].tendedDays == 12, "rumour with \(log[rumour].tendedDays) tended days")
        let arrival = try #require(log.firstIndex { $0.caglayanPhase == .arrived })
        #expect(arrival == rumour + WonderIslands.caglayanArrivalDays)
        #expect(log.allSatisfy { $0.kokeStage == 0 }, "Koke moved although nobody tapped it")
    }

    @Test
    func theIslandsSleepAtBedtime() {
        // D7: a tap on a wonder island at night changes nothing.
        let run = Self.tester(days: 7) { _ in 1 }
        var world = run.world
        let start = run.next
        #expect(run.visits[6].kokeStage < WonderIslands.healedStage)
        world.advance(to: start, applying: run.arrival)
        world.advance(to: start.adding(minutes: 2), applying: [.signOfLife(at: start.adding(minutes: 1)), .resisted(at: start.adding(minutes: 1))])
        let night = instant(2026, 11, 9, 23, 30)
        world.advance(to: night)
        #expect(world.clock.isBedtime(night))
        let before = world.state.wonders
        #expect(world.snapshot.koke.isAsleep)
        #expect(world.snapshot.caglayan.isAsleep)
        #expect(!world.snapshot.koke.canAdvance)
        #expect(!world.snapshot.caglayan.canAdvance)
        world.advance(to: night, GameEvent(at: night, kind: .tendedWonder(.koke)), GameEvent(at: night, kind: .tendedWonder(.caglayan)))
        #expect(world.state.wonders == before, "a wonder island moved at night")
    }
}
