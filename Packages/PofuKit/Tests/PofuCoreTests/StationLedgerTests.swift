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
        #expect(try spec(.cay).levelCosts == [8, 14, 24, 38, 60])
        #expect(try spec(.pond).levelCosts == [15, 25, 40, 60, 85])
        #expect(try spec(.workshop).levelCosts == [30, 50, 75, 105, 140])
        #expect(try spec(.windmill).levelCosts == [50, 80, 110, 150, 190])
        #expect(try spec(.simit).levelCosts == [25, 40, 60, 85, 115])
        #expect(try spec(.pier).levelCosts == [40, 60, 85, 115, 150])
        #expect(try spec(.lighthouse).levelCosts == [60, 85, 115, 150, 200])
        #expect(catalog.totalCost(of: .aycicegi) == 1_403)
        #expect(catalog.totalCost == 8_143)
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

    @Test func fiveIslandsSeventeenStationsFiveLevelsEach() {
        #expect(catalog.islands.map(\.id) == [.aycicegi, .iskele, .yildiz, .kaplica, .kitap])
        #expect(catalog.stations.count == 17)
        #expect(catalog.stations.allSatisfy { $0.maxLevel == 5 })
        #expect(Set(catalog.stations.map(\.id)).count == 17)
    }

    @Test func homeStagesFollowTendedDays() {
        #expect([0, 1, 3, 4, 9, 10, 23, 24, 400].map { catalog.homeStage(tendedDays: $0) } == [1, 2, 2, 3, 3, 4, 4, 5, 5])
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

    @Test func aStationOpensWithItsStage() {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(1_000)
        ledger.collect()
        #expect(throws: BuildError.notOpen(.cay)) { try ledger.build(.cay, tendedDays: 0, catalog: catalog) }
        #expect(throws: Never.self) { try ledger.build(.cay, tendedDays: 1, catalog: catalog) }
        #expect(throws: BuildError.notOpen(.simit)) { try ledger.build(.simit, tendedDays: 30, catalog: catalog) }
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
        for _ in 2...5 {
            try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        }
        #expect(ledger.jar == Energy(1_000 - 5 - 9 - 15 - 25))
        #expect(throws: BuildError.maxLevel(.garden)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
    }

    @Test func pendingSeedsCannotBuild() {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(100)
        #expect(throws: BuildError.notEnoughSeeds(needed: 5, have: 0)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
    }

    // MARK: - Islands

    @Test func iskeleWaitsForEightTendedDaysAndMochisStallAtLevelThree() throws {
        var ledger = StationLedger(catalog: catalog)
        let result3 = ledger.settleArrivals(tendedDays: 8, calmNights: 0, released: [], catalog: catalog)
        #expect(result3.isEmpty)
        ledger.gather(1_000)
        ledger.collect()
        for _ in 1...3 {
            try ledger.build(.cay, tendedDays: 8, catalog: catalog)
        }
        let result4 = ledger.settleArrivals(tendedDays: 7, calmNights: 0, released: [], catalog: catalog)
        #expect(result4.isEmpty)
        let result5 = ledger.settleArrivals(tendedDays: 8, calmNights: 0, released: [], catalog: catalog)
        #expect(result5 == [.iskele])
        #expect(ledger.arrivals[.iskele] == 8)
        // Its stations open 0, 3 and 7 tended days after it arrived.
        let simit = try spec(.simit)
        let pier = try spec(.pier)
        #expect(ledger.isOpen(simit, tendedDays: 8, catalog: catalog))
        #expect(!ledger.isOpen(pier, tendedDays: 10, catalog: catalog))
        #expect(ledger.isOpen(pier, tendedDays: 11, catalog: catalog))
    }

    @Test func yildizCountsCalmNightsNeverInARow() {
        var ledger = StationLedger(catalog: catalog)
        let result6 = ledger.settleArrivals(tendedDays: 21, calmNights: 9, released: [], catalog: catalog)
        #expect(result6.isEmpty)
        let result7 = ledger.settleArrivals(tendedDays: 21, calmNights: 10, released: [], catalog: catalog)
        #expect(result7 == [.yildiz])
    }

    @Test func kitapArrivesOnlyOnceReleased() {
        var ledger = StationLedger(catalog: catalog)
        let result8 = ledger.settleArrivals(tendedDays: 60, calmNights: 30, released: [], catalog: catalog)
        #expect(!result8.contains(.kitap))
        let result9 = ledger.settleArrivals(tendedDays: 60, calmNights: 30, released: [.kitap], catalog: catalog)
        #expect(result9 == [.kitap])
        // Arrivals never repeat or go back.
        let result10 = ledger.settleArrivals(tendedDays: 0, calmNights: 0, released: [], catalog: catalog)
        #expect(result10.isEmpty)
        #expect(ledger.hasArrived(.kitap))
    }
}
