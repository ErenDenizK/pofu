import Foundation
import Testing
@testable import PofuCore

/// The pre-planned archipelago (ADR-0016) and seeds as world material
/// (ADR-0015): the designed ladders, production, gifts, collection, builds,
/// and arrivals.
@Suite("Station ledger")
struct StationLedgerTests {
    let catalog = ArchipelagoCatalog.standard
    let day = LocalDay(year: 2026, month: 11, day: 2)

    func spec(_ id: StationID) throws -> StationSpec {
        try #require(catalog.station(id))
    }

    // MARK: - The designed ladders (game design §5)

    // Economy scale A (founder, 2026-11-02): the old ladders ran ×2.2 a
    // level up to 32,796; scale A keeps every level between 5 and 200
    // seeds, so these expectations changed from the v2 numbers to the
    // archipelago system's §7.4 table.
    @Test func theHomeIslandLaddersMatchTheGameDesign() throws {
        #expect(try spec(.garden).levelCosts == [0, 5, 9, 15, 25])
        #expect(try spec(.teaStall).levelCosts == [8, 14, 24, 38, 60])
        #expect(try spec(.pond).levelCosts == [15, 25, 40, 60, 85])
        #expect(try spec(.workshop).levelCosts == [30, 45, 65, 90, 120])
        #expect(try spec(.windmill).levelCosts == [40, 55, 75, 100, 130])
        #expect(try spec(.bagelCart).levelCosts == [12, 20, 32, 48, 70])
        #expect(try spec(.pier).levelCosts == [20, 32, 48, 70, 100])
        #expect(try spec(.lighthouse).levelCosts == [25, 40, 60, 85, 115])
        // Home progression section 4.1: the harbor was re-budgeted to 777.
        #expect(catalog.totalCost(of: .home) == 1_173)
        #expect(catalog.totalCost(of: .harbor) == 777)
        #expect(catalog.totalCost == 1_950)
    }

    @Test func everyPriceIsBetweenFiveAndTwoHundredAndRatesAreSmall() {
        let prices = catalog.stations.flatMap(\.levelCosts).filter { $0 > .zero }
        #expect(prices.allSatisfy { $0 >= 5 && $0 <= 200 })
        #expect(catalog.stations.allSatisfy { spec in
            spec.levelCosts.dropFirst().elementsEqual(spec.levelCosts.dropFirst().sorted())
        })
    }

    @Test func ratesGrowByTheSameStepEveryLevel() throws {
        // 0.02 of a seed an hour per level: about 0.5 a day at calm ×1.0.
        let garden = try spec(.garden)
        #expect((1...5).map { garden.seedsPerHour(at: $0) } == [0.02, 0.04, 0.06, 0.08, 0.1])
        let windmill = try spec(.windmill)
        #expect(windmill.seedsPerHour(at: 5) == 0.1)
        #expect(windmill.seedsPerHour(at: 0) == 0)
        #expect(windmill.cost(toReach: 6) == nil)
    }

    @Test func twoIslandsEightStationsFiveLevelsEach() {
        // Yildiz, Kaplica and Kitap are retired (game plan section 2).
        #expect(catalog.islands.map(\.id) == [.home, .harbor])
        #expect(catalog.stations.count == 8)
        #expect(catalog.stations.allSatisfy { $0.maxLevel == 5 })
        #expect(Set(catalog.stations.map(\.id)).count == 8)
    }

    @Test func slotsOpenByIslandLevel() {
        let opens = Dictionary(uniqueKeysWithValues: catalog.stations.map { ($0.id, $0.opensAt) })
        #expect(opens == [
            .garden: 1, .teaStall: 2, .bagelCart: 3, .pond: 4, .pier: 5, .workshop: 6, .lighthouse: 6, .windmill: 8,
        ])
    }

    @Test func homeStagesFollowTheOpenSlots() {
        #expect((1...10).map { catalog.homeStage(islandLevel: $0) } == [1, 2, 2, 3, 3, 4, 4, 5, 5, 5])
    }

    // MARK: - Production

    @Test func theGardenMakesAboutHalfASeedADayAtCalmOne() {
        var ledger = StationLedger(catalog: catalog)
        #expect(ledger.level(of: .garden) == 1)
        // 0.02 of a seed an hour: one whole seed after 50 hours (3,000
        // minutes), and not a unit sooner.
        var made = Energy.zero
        for _ in 0..<2_999 {
            made += ledger.produceMinute(calmTenths: 10, careTenths: 10, catalog: catalog)
        }
        #expect(made == 0)
        made += ledger.produceMinute(calmTenths: 10, careTenths: 10, catalog: catalog)
        #expect(made == 1)
        #expect(ledger.pending.stations == 1)
        #expect(ledger.productionCarry == 0)
    }

    @Test func calmAndCareScaleProduction() {
        var calm = StationLedger(catalog: catalog)
        var unwell = StationLedger(catalog: catalog)
        // Ten days of minutes: the garden at level 1 makes 4.8 seeds at
        // ×1.0, so 9.6 at calm ×2.0 and 2.88 while Pofu is unwell (×0.6).
        for _ in 0..<14_400 {
            calm.produceMinute(calmTenths: 20, careTenths: 10, catalog: catalog)
            unwell.produceMinute(calmTenths: 10, careTenths: 6, catalog: catalog)
        }
        #expect(calm.pending.stations == 9)
        #expect(unwell.pending.stations == 2)
    }

    @Test func fractionsCarrySoNothingIsLostBetweenMinutes() {
        var ledger = StationLedger(catalog: catalog)
        // 0.02 seeds an hour × 1.3 = 0.026 an hour: over ten days' worth of
        // minutes that is 6.24 seeds, which rounding each minute would lose
        // entirely; carried, they make 6 whole ones.
        for _ in 0..<14_400 {
            ledger.produceMinute(calmTenths: 13, careTenths: 10, catalog: catalog)
        }
        #expect(ledger.pending.stations == 6)
    }

    // MARK: - Gifts and collection

    @Test func resistedReachesGiveOneSeedForAtMostSixADay() {
        var ledger = StationLedger(catalog: catalog)
        let gifts = (0..<8).map { _ in ledger.giftSkip(on: day, rules: SeedRules()) }
        #expect(gifts == [1, 1, 1, 1, 1, 1, 0, 0])
        #expect(ledger.pending.skips == 6)
        let result1 = ledger.giftSkip(on: day.adding(days: 1), rules: SeedRules())
        #expect(result1 == 1)
    }

    @Test func collectingMovesThePouchIntoTheJar() {
        var ledger = StationLedger(catalog: catalog)
        let result2 = ledger.collect()
        #expect(result2 == nil)
        ledger.gather(4)
        ledger.addSleepBonus(2)
        ledger.giftSkip(on: day, rules: SeedRules())
        let collected = ledger.collect()
        #expect(collected == SeedPouch(gathered: 4, sleepBonus: 2, skips: 1))
        #expect(ledger.jar == 7)
        #expect(ledger.pending.isEmpty)
    }

    // MARK: - Builds

    @Test func buildsSpendFromTheJarOnTheNextDesignedLevel() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(100)
        ledger.collect()
        let receipt = try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        #expect(receipt == BuildReceipt(station: .garden, level: 2, cost: 5))
        #expect(ledger.jar == 95)
        #expect(ledger.level(of: .garden) == 2)
    }

    @Test func aStationOpensWithItsIslandLevel() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(1_000)
        ledger.collect()
        // Island level 2 needs the second tended day and two built levels.
        #expect(throws: BuildError.notOpen(.teaStall)) { try ledger.build(.teaStall, tendedDays: 1, catalog: catalog) }
        try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        #expect(throws: BuildError.notOpen(.teaStall)) { try ledger.build(.teaStall, tendedDays: 0, catalog: catalog) }
        #expect(throws: Never.self) { try ledger.build(.teaStall, tendedDays: 1, catalog: catalog) }
        // The harbor has not arrived, so its cart stays shut at any day.
        #expect(throws: BuildError.notOpen(.bagelCart)) { try ledger.build(.bagelCart, tendedDays: 30, catalog: catalog) }
        #expect(throws: BuildError.unknownStation("nope")) { try ledger.build("nope", tendedDays: 30, catalog: catalog) }
    }

    @Test func seedsMustCoverTheLevel() {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(4)
        ledger.collect()
        #expect(throws: BuildError.notEnoughSeeds(needed: 5, have: 4)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
        #expect(ledger.jar == 4)
        #expect(ledger.level(of: .garden) == 1)
    }

    @Test func thereIsNoSixthLevel() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(1_000)
        ledger.collect()
        // Day 400 with every station grown: the cap no longer holds the
        // garden at two.
        ledger.levels = Dictionary(uniqueKeysWithValues: catalog.stations.map { ($0.id, 4) })
        ledger.levels[.garden] = 1
        for _ in 2...5 {
            try ledger.build(.garden, tendedDays: 400, catalog: catalog)
        }
        #expect(ledger.jar == Energy(1_000 - 5 - 9 - 15 - 25))
        #expect(throws: BuildError.maxLevel(.garden)) { try ledger.build(.garden, tendedDays: 400, catalog: catalog) }
    }

    @Test func pendingSeedsCannotBuild() {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(100)
        #expect(throws: BuildError.notEnoughSeeds(needed: 5, have: 0)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
    }

    // MARK: - Islands

    @Test func harborArrivesOnTheThirdTendedDayOnceMochisStallStands() throws {
        var ledger = StationLedger(catalog: catalog)
        // Two days are done by the third: the fog lifts then, not before.
        #expect(ledger.settleArrivals(tendedDays: 2, calmNights: 0, released: [], catalog: catalog).isEmpty)
        ledger.gather(1_000)
        ledger.collect()
        try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        try ledger.build(.teaStall, tendedDays: 1, catalog: catalog)
        #expect(ledger.settleArrivals(tendedDays: 1, calmNights: 0, released: [], catalog: catalog).isEmpty)
        #expect(ledger.settleArrivals(tendedDays: 2, calmNights: 0, released: [], catalog: catalog) == [.harbor])
        #expect(ledger.arrivals[.harbor] == 2)
        // Its slots open by island level: the cart at 3, the pier at 5, the
        // lighthouse at 6.
        let bagelCart = try spec(.bagelCart)
        let pier = try spec(.pier)
        #expect(ledger.isOpen(bagelCart, tendedDays: 2, catalog: catalog))
        #expect(!ledger.isOpen(pier, tendedDays: 400, catalog: catalog))
    }

    @Test func arrivalsNeverRepeatOrGoBack() {
        var ledger = StationLedger(catalog: catalog)
        ledger.levels[.teaStall] = 1
        #expect(ledger.settleArrivals(tendedDays: 60, calmNights: 30, released: [], catalog: catalog) == [.harbor])
        #expect(ledger.settleArrivals(tendedDays: 0, calmNights: 0, released: [], catalog: catalog).isEmpty)
        #expect(ledger.hasArrived(.harbor))
    }

    // MARK: - Retired station islands (2026-11-05)

    @Test func aSaveWithRetiredIslandsLoadsAndRefundsTheirLevels() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.levels[.teaStall] = 2
        ledger.levels["observatory"] = 2
        ledger.levels["hamam"] = 1
        ledger.arrivals[.harbor] = 8
        ledger.arrivals["yildiz"] = 21
        ledger.arrivals["kaplica"] = 35
        ledger.arrivalOrder += [.harbor, "yildiz", "kaplica"]
        ledger.jar = 10
        let loaded = try JSONDecoder().decode(StationLedger.self, from: JSONEncoder().encode(ledger))
        #expect(loaded.arrivalOrder == [.home, .harbor])
        #expect(loaded.arrivals == [.home: 0, .harbor: 8])
        #expect(loaded.levels == [.garden: 1, .teaStall: 2])
        // Observatory 1 and 2 (45 + 70) and the hamam's first level (60).
        #expect(loaded.jar.units == 10 + 45 + 70 + 60)
        // The rest is untouched, and a second round trip changes nothing.
        let again = try JSONDecoder().decode(StationLedger.self, from: JSONEncoder().encode(loaded))
        #expect(again == loaded)
    }

    // MARK: - Saves written before the English rename (2026-11-03)

    @Test func oldTurkishIdsDecodeAsTheEnglishOnes() throws {
        let decoder = JSONDecoder()
        let stations = try decoder.decode([StationID].self, from: Data(#"["cay","simit","garden"]"#.utf8))
        #expect(stations == [.teaStall, .bagelCart, .garden])
        let islands = try decoder.decode([IslandID].self, from: Data(#"["aycicegi","iskele","kitap"]"#.utf8))
        #expect(islands == [.home, .harbor, "kitap"])
        // The keyed shape an older build may have written.
        let keyed = try decoder.decode([StationID].self, from: Data(#"[{"rawValue":"cay"}]"#.utf8))
        #expect(keyed == [.teaStall])
    }

    @Test func aLedgerSavedWithOldIdsKeepsItsLevelsAndArrivals() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.levels[.teaStall] = 3
        ledger.levels[.bagelCart] = 1
        ledger.arrivals[.harbor] = 8
        ledger.arrivalOrder.append(.harbor)
        let english = String(decoding: try JSONEncoder().encode(ledger), as: UTF8.self)
        #expect(!english.contains("aycicegi") && !english.contains("\"cay\"") && !english.contains("iskele"))
        let old = english
            .replacingOccurrences(of: "\"teaStall\"", with: "\"cay\"")
            .replacingOccurrences(of: "\"bagelCart\"", with: "\"simit\"")
            .replacingOccurrences(of: "\"home\"", with: "\"aycicegi\"")
            .replacingOccurrences(of: "\"harbor\"", with: "\"iskele\"")
        #expect(old != english)
        let loaded = try JSONDecoder().decode(StationLedger.self, from: Data(old.utf8))
        #expect(loaded == ledger)
    }

    @Test func idsAreWrittenInEnglish() throws {
        let data = try JSONEncoder().encode([StationID.teaStall, .bagelCart])
        #expect(String(decoding: data, as: UTF8.self) == #"["teaStall","bagelCart"]"#)
    }
}
