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

    @Test func theHomeIslandLaddersMatchTheGameDesign() throws {
        #expect(try spec(.garden).levelCosts == [0, 30, 66, 145, 319])
        #expect(try spec(.cay).levelCosts == [40, 88, 194, 426, 937])
        #expect(try spec(.pond).levelCosts == [160, 352, 774, 1_704, 3_748])
        #expect(try spec(.workshop).levelCosts == [500, 1_100, 2_420, 5_324, 11_713])
        #expect(try spec(.windmill).levelCosts == [1_400, 3_080, 6_776, 14_907, 32_796])
        #expect(try spec(.simit).levelCosts == [300, 660, 1_452, 3_194, 7_028])
        #expect(try spec(.pier).levelCosts == [550, 1_210, 2_662, 5_856, 12_884])
        #expect(try spec(.lighthouse).levelCosts == [1_000, 2_200, 4_840, 10_648, 23_426])
        #expect(catalog.totalCost(of: .aycicegi) == 88_999)
        #expect(catalog.totalCost == 1_944_103)
    }

    @Test func ratesGrowFiftyFivePercentOfBasePerLevel() throws {
        let garden = try spec(.garden)
        #expect((1...5).map { garden.seedsPerHour(at: $0) } == [6, 9.3, 12.6, 15.9, 19.2])
        let windmill = try spec(.windmill)
        #expect(windmill.seedsPerHour(at: 5) == 38.4)
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

    @Test func theGardenMakesSixSeedsAnHourAtCalmOne() {
        var ledger = StationLedger(catalog: catalog)
        #expect(ledger.level(of: .garden) == 1)
        var made = Energy.zero
        for _ in 0..<60 {
            made += ledger.produceMinute(calmTenths: 10, careTenths: 10, catalog: catalog)
        }
        #expect(made == 6)
        #expect(ledger.pending.stations == 6)
        #expect(ledger.productionCarry == 0)
    }

    @Test func calmAndCareScaleProduction() {
        var calm = StationLedger(catalog: catalog)
        var unwell = StationLedger(catalog: catalog)
        for _ in 0..<600 {
            calm.produceMinute(calmTenths: 20, careTenths: 10, catalog: catalog)
            unwell.produceMinute(calmTenths: 10, careTenths: 6, catalog: catalog)
        }
        #expect(calm.pending.stations == 120)
        #expect(unwell.pending.stations == 36)
    }

    @Test func fractionsCarrySoNothingIsLostBetweenMinutes() {
        var ledger = StationLedger(catalog: catalog)
        // 6 seeds an hour × 1.3 = 7.8 an hour: 78 in ten hours.
        for _ in 0..<600 {
            ledger.produceMinute(calmTenths: 13, careTenths: 10, catalog: catalog)
        }
        #expect(ledger.pending.stations == 78)
    }

    // MARK: - Gifts and collection

    @Test func resistedReachesGiveThreeSeedsForAtMostFiveADay() {
        var ledger = StationLedger(catalog: catalog)
        let gifts = (0..<8).map { _ in ledger.giftSkip(on: day, rules: SeedRules()) }
        #expect(gifts == [3, 3, 3, 3, 3, 0, 0, 0])
        #expect(ledger.pending.skips == 15)
        let result1 = ledger.giftSkip(on: day.adding(days: 1), rules: SeedRules())
        #expect(result1 == 3)
    }

    @Test func collectingMovesThePouchIntoTheJar() {
        var ledger = StationLedger(catalog: catalog)
        let result2 = ledger.collect()
        #expect(result2 == nil)
        ledger.gather(4)
        ledger.addSleepBonus(10)
        ledger.giftSkip(on: day, rules: SeedRules())
        let collected = ledger.collect()
        #expect(collected == SeedPouch(gathered: 4, sleepBonus: 10, skips: 3))
        #expect(ledger.jar == 17)
        #expect(ledger.pending.isEmpty)
    }

    // MARK: - Builds

    @Test func buildsSpendFromTheJarOnTheNextDesignedLevel() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(100)
        ledger.collect()
        let receipt = try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        #expect(receipt == BuildReceipt(station: .garden, level: 2, cost: 30))
        #expect(ledger.jar == 70)
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
        ledger.gather(29)
        ledger.collect()
        #expect(throws: BuildError.notEnoughSeeds(needed: 30, have: 29)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
        #expect(ledger.jar == 29)
        #expect(ledger.level(of: .garden) == 1)
    }

    @Test func thereIsNoSixthLevel() throws {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(1_000)
        ledger.collect()
        for _ in 2...5 {
            try ledger.build(.garden, tendedDays: 0, catalog: catalog)
        }
        #expect(ledger.jar == 1_000 - 30 - 66 - 145 - 319)
        #expect(throws: BuildError.maxLevel(.garden)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
    }

    @Test func pendingSeedsCannotBuild() {
        var ledger = StationLedger(catalog: catalog)
        ledger.gather(100)
        #expect(throws: BuildError.notEnoughSeeds(needed: 30, have: 0)) { try ledger.build(.garden, tendedDays: 0, catalog: catalog) }
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
