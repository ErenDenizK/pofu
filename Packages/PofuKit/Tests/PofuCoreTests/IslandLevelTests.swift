import Foundation
import Testing
@testable import PofuCore

/// The island level (*Ada seviyesi*), its gate (tended days and built
/// levels) and the station caps it sets: home progression section 3.
@Suite("Island level")
struct IslandLevelTests {
    let catalog = ArchipelagoCatalog.standard

    func ledger(levels: [StationID: Int]) -> StationLedger {
        var ledger = StationLedger(catalog: catalog)
        ledger.levels = levels
        return ledger
    }

    // MARK: - The table

    @Test func theTableMatchesHomeProgression() {
        #expect(catalog.islandLevels.map(\.level) == Array(1...10))
        #expect(catalog.islandLevels.map(\.tendedDayFloor) == [1, 2, 3, 4, 6, 10, 14, 20, 30, 36])
        #expect(catalog.islandLevels.map(\.growth) == [0, 2, 3, 6, 10, 15, 20, 26, 34, 40])
        #expect(catalog.islandLevels.map(\.stationCap) == [2, 2, 3, 3, 4, 4, 5, 5, 5, 5])
        // Floors and growth only rise, and so do the caps: nothing falls.
        for (a, b) in zip(catalog.islandLevels, catalog.islandLevels.dropFirst()) {
            #expect(a.tendedDayFloor <= b.tendedDayFloor && a.growth < b.growth && a.stationCap <= b.stationCap)
        }
        // The last level is every one of the eight stations at level 5.
        #expect(catalog.islandLevels.last?.growth == catalog.stations.map(\.maxLevel).reduce(0, +))
    }

    @Test func bothTheFloorAndTheGrowthMustBeMet() {
        // Days alone never raise the level, and neither does growth alone.
        #expect(catalog.islandLevel(tendedDays: 400, growth: 1) == 1)
        #expect(catalog.islandLevel(tendedDays: 0, growth: 39) == 1)
        #expect(catalog.islandLevel(tendedDays: 1, growth: 2) == 2)
        #expect(catalog.islandLevel(tendedDays: 1, growth: 99) == 2)
        #expect(catalog.islandLevel(tendedDays: 2, growth: 3) == 3)
        #expect(catalog.islandLevel(tendedDays: 2, growth: 5) == 3)
        #expect(catalog.islandLevel(tendedDays: 3, growth: 6) == 4)
        #expect(catalog.islandLevel(tendedDays: 19, growth: 25) == 7)
        #expect(catalog.islandLevel(tendedDays: 18, growth: 33) == 7)
        #expect(catalog.islandLevel(tendedDays: 19, growth: 26) == 8)
        #expect(catalog.islandLevel(tendedDays: 28, growth: 40) == 8)
        #expect(catalog.islandLevel(tendedDays: 29, growth: 33) == 8)
        #expect(catalog.islandLevel(tendedDays: 29, growth: 34) == 9)
        #expect(catalog.islandLevel(tendedDays: 35, growth: 39) == 9)
        #expect(catalog.islandLevel(tendedDays: 35, growth: 40) == 10)
        #expect(catalog.islandLevel(tendedDays: 34, growth: 40) == 9)
    }

    @Test func theLevelIsMonotonicInDaysAndGrowth() {
        var previous = 1
        for days in 0...60 {
            for growth in 0...40 {
                let level = catalog.islandLevel(tendedDays: days, growth: growth)
                #expect(level >= catalog.islandLevel(tendedDays: max(0, days - 1), growth: growth))
                #expect(level >= catalog.islandLevel(tendedDays: days, growth: max(0, growth - 1)))
                previous = max(previous, level)
            }
        }
        #expect(previous == 10)
    }

    @Test func theLedgerDerivesTheLevelFromBuiltLevels() {
        let fresh = StationLedger(catalog: catalog)
        #expect(fresh.growth(catalog: catalog) == 1)
        #expect(fresh.islandLevel(tendedDays: 0, catalog: catalog) == 1)
        let grown = ledger(levels: [.garden: 3, .teaStall: 2, .bagelCart: 1])
        #expect(grown.growth(catalog: catalog) == 6)
        #expect(grown.islandLevel(tendedDays: 3, catalog: catalog) == 4)
        #expect(grown.islandLevel(tendedDays: 2, catalog: catalog) == 3)
    }

    // MARK: - What the next level waits for

    @Test func theNextLevelSaysWhatIsLeftNeverATimer() {
        let fresh = StationLedger(catalog: catalog)
        #expect(fresh.nextIslandLevelRequirement(tendedDays: 0, catalog: catalog)
            == IslandLevelRequirement(level: 2, tendedDaysLeft: 1, levelsLeft: 1))
        let grown = ledger(levels: [.garden: 4, .teaStall: 3, .bagelCart: 2, .pond: 1])
        // Ada 5 needs 10 levels and the 6th day.
        #expect(grown.nextIslandLevelRequirement(tendedDays: 3, catalog: catalog)
            == IslandLevelRequirement(level: 5, tendedDaysLeft: 2, levelsLeft: 0))
        // Once the 6th day comes, Ada 5 is here and Ada 6 waits for levels.
        #expect(grown.nextIslandLevelRequirement(tendedDays: 5, catalog: catalog)
            == IslandLevelRequirement(level: 6, tendedDaysLeft: 4, levelsLeft: 5))
        let full = ledger(levels: Dictionary(uniqueKeysWithValues: catalog.stations.map { ($0.id, 5) }))
        #expect(full.islandLevel(tendedDays: 60, catalog: catalog) == 10)
        #expect(full.nextIslandLevelRequirement(tendedDays: 60, catalog: catalog) == nil)
    }

    // MARK: - Station caps

    @Test func theCapRisesWithTheIslandLevel() throws {
        let garden = try #require(catalog.station(.garden))
        var ledger = ledger(levels: [.garden: 2])
        // Day 1, Ada 1: the cap is two, the third level waits for Ada 3.
        #expect(ledger.maxLevel(of: garden, tendedDays: 0, catalog: catalog) == 2)
        ledger.gather(500)
        ledger.collect()
        #expect(throws: BuildError.capped(.garden, cap: 2, liftsAtIslandLevel: 3)) {
            try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        }
        // Nothing was spent or built by the refusal.
        #expect(ledger.jar == 500 && ledger.level(of: .garden) == 2)
        // Ada 3: three built levels and the third day.
        ledger.levels[.teaStall] = 1
        #expect(ledger.maxLevel(of: garden, tendedDays: 2, catalog: catalog) == 3)
        #expect(throws: Never.self) { try ledger.build(.garden, tendedDays: 2, catalog: catalog) }
        // The fourth level waits for Ada 5 (cap 4).
        #expect(throws: BuildError.capped(.garden, cap: 3, liftsAtIslandLevel: 5)) {
            try ledger.build(.garden, tendedDays: 2, catalog: catalog)
        }
    }

    @Test func aCapNeverExceedsTheStationsOwnTop() throws {
        let garden = try #require(catalog.station(.garden))
        let full = ledger(levels: Dictionary(uniqueKeysWithValues: catalog.stations.map { ($0.id, 5) }))
        #expect(full.maxLevel(of: garden, tendedDays: 100, catalog: catalog) == 5)
        let narrow = StationSpec.ladder("narrow", island: .home, opensAt: 1, costs: [5, 6, 7])
        #expect(full.maxLevel(of: narrow, tendedDays: 100, catalog: catalog) == 3)
    }

    @Test func levelsBuiltAboveALaterLowerCapStayBuilt() throws {
        // An old save can hold a level above today's cap; nothing is taken
        // away (ADR-0017), and it simply cannot go higher until the cap does.
        var ledger = ledger(levels: [.garden: 5])
        ledger.gather(500)
        ledger.collect()
        #expect(throws: BuildError.maxLevel(.garden)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
        #expect(ledger.level(of: .garden) == 5)
    }

    @Test func theSnapshotExposesTheCapAndWhenItLifts() throws {
        var world = World()
        let first = instant(2026, 11, 2, 8)
        world.advance(to: first, .signOfLife(at: first))
        world.state.stations.gather(500)
        world.state.stations.collect()
        try world.build(.garden, at: first)
        let garden = try #require(world.snapshot.stations.first { $0.id == .garden })
        #expect(garden.level == 2 && garden.maxLevel == 5 && garden.levelCap == 2)
        #expect(garden.isCapped && garden.capLiftsAtIslandLevel == 3)
        #expect(world.snapshot.islandLevel == 1)
        #expect(world.snapshot.nextIslandLevel == IslandLevelRequirement(level: 2, tendedDaysLeft: 1, levelsLeft: 0))
    }

    // MARK: - No dead end

    @Test func everyIslandLevelCanReachTheNextWithoutAnythingNotYetOpen() {
        // Rule 1: at each island level, the open stations times the cap
        // reach the next level's growth, so a player is never stuck behind
        // a cap that only the growth they cannot build would lift.
        for rule in catalog.islandLevels.dropLast() {
            let open = catalog.stations.filter { $0.opensAt <= rule.level }
            let reachable = open.reduce(0) { $0 + min($1.maxLevel, rule.stationCap) }
            let next = catalog.islandLevels[rule.level]
            #expect(reachable >= next.growth, "Ada \(rule.level): \(reachable) reachable, Ada \(next.level) needs \(next.growth)")
        }
    }

    @Test func theNextGoalIsAlwaysSmallAtEveryIslandLevel() {
        // Whatever the island level, the cheapest open level under the cap
        // is a price of at most 130 seeds (about three days at the
        // week-eight income, one at the start).
        for rule in catalog.islandLevels {
            let costs = catalog.stations.filter { $0.opensAt <= rule.level }.flatMap { station in
                (1...min(station.maxLevel, rule.stationCap)).compactMap { station.cost(toReach: $0) }
            }
            #expect((costs.filter { $0 > .zero }.max() ?? 0) <= 130, "Ada \(rule.level)")
        }
    }

    // MARK: - Old saves

    @Test func anOldSaveWithRetiredIslandsLoadsIntoTheIslandLevelGame() throws {
        var state = GameState(rules: GameRules())
        state.tendedDays = 30
        state.stations.levels[.teaStall] = 3
        state.stations.levels["fireflies"] = 1
        state.stations.arrivals[.harbor] = 8
        state.stations.arrivals["yildiz"] = 21
        state.stations.arrivalOrder += [.harbor, "yildiz"]
        let loaded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(loaded.stations.arrivalOrder == [.home, .harbor])
        #expect(loaded.stations.level(of: "fireflies") == 0)
        #expect(loaded.stations.jar == 55)
        #expect(loaded.stations.level(of: .teaStall) == 3)
        let snapshot = WorldClock(rules: GameRules(), calendar: .istanbul).snapshot(of: loaded)
        #expect(snapshot.islands == [.home, .harbor])
        #expect(!snapshot.stations.contains { $0.id == "fireflies" })
    }

    // MARK: - The next goal

    /// The goal line never reads "0 more days": a requirement the game
    /// reports always has something left.
    @Test func theNextLevelsRequirementIsNeverAlreadyMet() {
        for tendedDays in 0...120 {
            for growth in 0...60 {
                let level = catalog.islandLevel(tendedDays: tendedDays, growth: growth)
                guard let next = catalog.requirement(afterIslandLevel: level, tendedDays: tendedDays, growth: growth) else { continue }
                #expect(!next.isMet, "days \(tendedDays), growth \(growth)")
            }
        }
        #expect(IslandLevelRequirement(level: 3, tendedDaysLeft: 0, levelsLeft: 0).isMet)
        #expect(!IslandLevelRequirement(level: 3, tendedDaysLeft: 1, levelsLeft: 0).isMet)
        #expect(!IslandLevelRequirement(level: 3, tendedDaysLeft: 0, levelsLeft: 2).isMet)
    }
}
