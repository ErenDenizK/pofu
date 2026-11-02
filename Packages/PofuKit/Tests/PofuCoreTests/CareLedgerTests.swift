import Foundation
import Testing
@testable import PofuCore

/// Pofu's wellbeing (game design §5, ADR-0017): drain, heal, skips, nights,
/// bands, and the floor he never goes below.
@Suite("Care ledger")
struct CareLedgerTests {
    let rules = CareRules()
    let day = LocalDay(year: 2026, month: 11, day: 2)

    @Test func startsAtSeventyAndContent() {
        let care = CareLedger(rules: rules)
        #expect(care.wellbeing == 70)
        #expect(care.band(rules: rules) == .content)
        #expect(care.productionTenths(rules: rules) == 10)
    }

    @Test func anHourInAGuardedAppDrainsTwentyOne() {
        var care = CareLedger(rules: rules)
        for _ in 0..<60 {
            care.drainMinute(earlierOpens: 0, atNight: false, rules: rules)
        }
        #expect(abs(care.wellbeing - (70 - 21)) < 1e-9)
    }

    @Test func nightAndEarlierOpensMakeTheDrainSteeper() {
        var plain = CareLedger(wellbeing: 80, rules: rules)
        var night = plain
        var escalated = plain
        plain.drainMinute(earlierOpens: 0, atNight: false, rules: rules)
        night.drainMinute(earlierOpens: 0, atNight: true, rules: rules)
        escalated.drainMinute(earlierOpens: 2, atNight: false, rules: rules)
        #expect(abs((80 - plain.wellbeing) - 0.35) < 1e-9)
        #expect(abs((80 - night.wellbeing) - 0.70) < 1e-9)
        #expect(abs((80 - escalated.wellbeing) - 0.35 * 1.25 * 1.25) < 1e-9)
    }

    @Test func pofuNeverGoesBelowTheFloor() {
        var care = CareLedger(wellbeing: 6, rules: rules)
        for _ in 0..<10_000 {
            care.drainMinute(earlierOpens: 12, atNight: true, rules: rules)
            care.opened(rules: rules)
        }
        #expect(care.wellbeing == 5)
        #expect(care.band(rules: rules) == .curledUp)
        #expect(CareLedger(wellbeing: -40, rules: rules).wellbeing == 5)
        #expect(CareLedger(wellbeing: .nan, rules: rules).wellbeing == 5)
        #expect(CareLedger(wellbeing: 400, rules: rules).wellbeing == 100)
    }

    @Test func aQuietHourHealsTheBottomBandsByTheirWidth() {
        var curled = CareLedger(wellbeing: 5, rules: rules)
        for _ in 0..<30 {
            curled.healMinute(rules: rules)
        }
        #expect(abs(curled.wellbeing - 8.5) < 1e-6)
    }

    /// ADR-0017: one quiet hour lifts Pofu out of the bottom, from the
    /// floor.
    @Test func oneQuietHourLiftsACurledUpPofuABand() {
        var care = CareLedger(wellbeing: 5, rules: rules)
        #expect(care.band(rules: rules) == .curledUp)
        for _ in 0..<60 {
            care.healMinute(rules: rules)
        }
        #expect(care.band(rules: rules) == .unwell)
    }

    /// From anywhere in the two lowest bands, one quiet hour reaches the
    /// next band edge.
    @Test(arguments: [UInt64(1), 2, 3])
    func inTheBottomBandsOneQuietHourReachesTheNextEdge(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var starts: [Double] = [5, 5 + 1e-9, 11.99, 12 - 1e-9, 12, 12 + 1e-9, 24.99, 25 - 1e-9]
        starts += (0..<200).map { _ in Double.random(in: 5..<25, using: &rng) }
        for start in starts {
            var care = CareLedger(wellbeing: start, rules: rules)
            let edge = start < 12 ? 12.0 : 25.0
            for _ in 0..<60 {
                care.healMinute(rules: rules)
            }
            #expect(care.wellbeing >= edge, "from \(start): \(care.wellbeing)")
            // Never a band further than the promise within the hour.
            #expect(care.wellbeing < edge + 13, "from \(start): \(care.wellbeing)")
        }
    }

    /// From "tired" up, one quiet hour heals exactly 5, capped at 100.
    @Test(arguments: [UInt64(1), 2, 3])
    func aboveTheBottomOneQuietHourHealsFive(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var starts: [Double] = [25, 49.99, 50, 74.99, 75, 94.5, 95, 97, 100]
        starts += (0..<200).map { _ in Double.random(in: 25...100, using: &rng) }
        for start in starts {
            var care = CareLedger(wellbeing: start, rules: rules)
            for _ in 0..<60 {
                care.healMinute(rules: rules)
            }
            #expect(abs(care.wellbeing - min(100, start + 5)) < 1e-9, "from \(start): \(care.wellbeing)")
        }
    }

    @Test func skipsHealOneForAtMostSixADay() {
        var care = CareLedger(wellbeing: 50, rules: rules)
        let healed = (0..<9).map { _ in care.skipped(on: day, rules: rules) }
        #expect(healed == [true, true, true, true, true, true, false, false, false])
        #expect(care.wellbeing == 56)
        let result1 = care.skipped(on: day.adding(days: 1), rules: rules)
        #expect(result1)
        #expect(care.wellbeing == 57)
    }

    @Test func pofuSleepsItOff() {
        var low = CareLedger(wellbeing: 20, rules: rules)
        low.nightEnded(calm: false, rules: rules)
        #expect(abs(low.wellbeing - 32) < 1e-9)

        var high = CareLedger(wellbeing: 80, rules: rules)
        high.nightEnded(calm: false, rules: rules)
        #expect(high.wellbeing == 80)

        var calm = CareLedger(wellbeing: 20, rules: rules)
        calm.nightEnded(calm: true, rules: rules)
        #expect(abs(calm.wellbeing - 42) < 1e-9)
    }

    @Test(arguments: [
        (100.0, WellbeingBand.cozy), (75, .cozy), (74.9, .content), (50, .content), (49.9, .tired),
        (25, .tired), (24.9, .unwell), (12, .unwell), (11.9, .curledUp), (5, .curledUp),
    ])
    func bands(wellbeing: Double, band: WellbeingBand) {
        #expect(CareLedger(wellbeing: wellbeing, rules: rules).band(rules: rules) == band)
    }

    @Test func belowTiredTheResidentsLookAfterPofu() {
        #expect(CareLedger(wellbeing: 25, rules: rules).productionTenths(rules: rules) == 10)
        #expect(CareLedger(wellbeing: 24.9, rules: rules).productionTenths(rules: rules) == 6)
    }
}
