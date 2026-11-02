import Foundation
import Testing
@testable import PofuCore

/// The calm multiplier (game design §5): growth, the quick check's halving,
/// the chain rule, resets, and calm nights.
@Suite("Calm accrual")
struct CalmAccrualTests {
    let rules = CalmRules()
    let noon = instant(2026, 11, 2, 12)

    func calm(_ tenths: Int) -> CalmAccrual {
        CalmAccrual(tenths: tenths, rules: rules)
    }

    @Test func growsATenthPerTwentyCalmMinutesUpToTwo() {
        var accrual = CalmAccrual(rules: rules)
        #expect(accrual.multiplier == 1.0)
        for _ in 0..<19 {
            let result1 = accrual.calmMinute(rules: rules)
            #expect(!result1)
        }
        let result2 = accrual.calmMinute(rules: rules)
        #expect(result2)
        #expect(accrual.tenths == 11)
        for _ in 0..<(180 - 20) {
            accrual.calmMinute(rules: rules)
        }
        #expect(accrual.tenths == 19)
        for _ in 0..<20 {
            accrual.calmMinute(rules: rules)
        }
        #expect(accrual.tenths == 20)
        #expect(accrual.isFull(rules: rules))
        for _ in 0..<200 {
            accrual.calmMinute(rules: rules)
        }
        #expect(accrual.tenths == 20)
        #expect(accrual.progressToNextStep(rules: rules) == 1)
    }

    @Test func aBrokenRunLosesOnlyTheProgress() {
        var accrual = calm(14)
        for _ in 0..<15 {
            accrual.calmMinute(rules: rules)
        }
        #expect(accrual.progressToNextStep(rules: rules) == 0.75)
        accrual.breakRun()
        #expect(accrual.tenths == 14)
        #expect(accrual.progressToNextStep(rules: rules) == 0)
    }

    @Test(arguments: [(16, 13), (20, 15), (11, 10), (10, 10), (13, 11), (19, 14)])
    func aQuickCheckHalvesTheBonusRoundedDown(before: Int, after: Int) {
        var accrual = calm(before)
        let change = accrual.opened(passMinutes: 3, isEmergency: false, startedAt: noon, rules: rules)
        #expect(change.kind == .quickCheck)
        #expect(accrual.tenths == after)
    }

    @Test func aFullOpenResets() {
        var accrual = calm(18)
        let change = accrual.opened(passMinutes: 15, isEmergency: false, startedAt: noon, rules: rules)
        #expect(change == CalmChange(kind: .fullOpen, beforeTenths: 18, afterTenths: 10))
        #expect(change.lowered)
    }

    @Test func aQuickCheckWithinTwentyMinutesOfTheLastOnesEndIsAFullOpen() {
        var accrual = calm(20)
        let result3 = accrual.opened(passMinutes: 3, isEmergency: false, startedAt: noon, rules: rules)
        #expect(result3.kind == .quickCheck)
        #expect(accrual.tenths == 15)
        // The first ended at 12:03; 12:22:59 is inside the chain.
        let chained = accrual.opened(passMinutes: 2, isEmergency: false, startedAt: noon.adding(minutes: 22).addingTimeInterval(59), rules: rules)
        #expect(chained.kind == .fullOpen)
        #expect(accrual.tenths == 10)
    }

    @Test func aQuickCheckTwentyMinutesAfterTheLastOnesEndHalvesAgain() {
        var accrual = calm(20)
        accrual.opened(passMinutes: 3, isEmergency: false, startedAt: noon, rules: rules)
        let next = accrual.opened(passMinutes: 3, isEmergency: false, startedAt: noon.adding(minutes: 23), rules: rules)
        #expect(next.kind == .quickCheck)
        #expect(accrual.tenths == 12)
    }

    @Test func theEmergencyPassResetsEvenWhenShort() {
        var accrual = calm(18)
        let result4 = accrual.opened(passMinutes: 3, isEmergency: true, startedAt: noon, rules: rules)
        #expect(result4.kind == .fullOpen)
        #expect(accrual.tenths == 10)
    }

    @Test func aCalmNightAddsTwoTenthsUpToTheMaximum() {
        var accrual = calm(15)
        accrual.calmNight(rules: rules)
        #expect(accrual.tenths == 17)
        var nearlyFull = calm(19)
        nearlyFull.calmNight(rules: rules)
        #expect(nearlyFull.tenths == 20)
    }

    @Test func calmStaysWithinOneAndTwo() {
        #expect(calm(3).tenths == 10)
        #expect(calm(31).tenths == 20)
    }

    /// Invariant (game design §13): a quick check never lowers calm by more
    /// than half the bonus.
    @Test func aQuickCheckNeverTakesMoreThanHalfTheBonus() {
        for tenths in 10...20 {
            var accrual = calm(tenths)
            let change = accrual.opened(passMinutes: 1, isEmergency: false, startedAt: noon, rules: rules)
            #expect(change.kind == .quickCheck)
            let bonusBefore = tenths - 10
            let lost = tenths - accrual.tenths
            #expect(2 * lost <= bonusBefore + 1)
            #expect(accrual.tenths >= 10)
        }
    }

    @Test func theGateRulesDefineTheQuickCheck() {
        var gate = ScreenTimeGateRules()
        gate.quickCheckMinutes = 5
        gate.quickCheckChainInterval = 600
        let derived = CalmRules(gate: gate)
        #expect(derived.quickCheckMinutes == 5)
        #expect(derived.quickCheckChain == 600)
    }
}

/// The breathing break (ADR-0015 v2): 5 s, 10 s from the 4th over-limit
/// open, never more than 10 s, never without a tap, never for seeds.
@Suite("Breath rules")
struct BreathRulesTests {
    let rules = BreathRules()

    @Test func noBreathUnderTheDailyHour() {
        #expect(rules.requirement(guardedMinutes: 59, overLimitOpensToday: 0) == nil)
    }

    @Test func fiveSecondsForTheFirstThreeThenTen() {
        let seconds = (0..<8).map { rules.requirement(guardedMinutes: 60, overLimitOpensToday: $0)?.seconds }
        #expect(seconds == [5, 5, 5, 10, 10, 10, 10, 10])
        #expect(rules.requirement(guardedMinutes: 90, overLimitOpensToday: 2)?.overLimitOrdinal == 3)
    }

    @Test func neverLongerThanTenSecondsWhateverTheConfiguration() {
        let generous = BreathRules(dailyHourMinutes: 15, shortSeconds: 30, longSeconds: 90, longFromOpen: 2)
        for opens in 0..<20 {
            let requirement = generous.requirement(guardedMinutes: 200, overLimitOpensToday: opens, isRapidReachFallback: opens.isMultiple(of: 2))
            #expect((requirement?.seconds ?? 0) <= BreathRules.capSeconds)
        }
        #expect(BreathRequirement(reason: .dailyHour, seconds: 45, overLimitOrdinal: 1).seconds == 10)
    }

    @Test func theBreathStartsOnlyOnATapAndBreathesTwoToThree() {
        let short = rules.requirement(guardedMinutes: 60, overLimitOpensToday: 0)
        #expect(short?.startsOnTap == true)
        #expect(short?.inhaleSeconds == 2)
        #expect(short?.exhaleSeconds == 3)
        let long = rules.requirement(guardedMinutes: 60, overLimitOpensToday: 3)
        #expect(long?.inhaleSeconds == 4)
        #expect(long?.exhaleSeconds == 6)
    }

    @Test func theFourthRapidReachFallsBackToTheLongBreath() {
        let underTheHour = rules.requirement(guardedMinutes: 10, overLimitOpensToday: 0, isRapidReachFallback: true)
        #expect(underTheHour == BreathRequirement(reason: .rapidReach, seconds: 10, overLimitOrdinal: nil))
        let pastTheHour = rules.requirement(guardedMinutes: 70, overLimitOpensToday: 0, isRapidReachFallback: true)
        #expect(pastTheHour?.seconds == 10)
        #expect(pastTheHour?.overLimitOrdinal == 1)
    }

    @Test func theEmergencyPassIsNeverBreathed() {
        #expect(rules.requirement(guardedMinutes: 500, overLimitOpensToday: 9, isRapidReachFallback: true, isEmergency: true) == nil)
    }

    @Test func notNowAndSkippingAfterTheBreathAreSkips() {
        #expect(BreathChoice.notNow.countsAsSkip)
        #expect(BreathChoice.skipAfterBreath.countsAsSkip)
        #expect(!BreathChoice.open.countsAsSkip)
    }

    @Test func theUsersDailyHourDrivesTheBreath() {
        let gate = ScreenTimeGateRules().withDailyHour(30)
        let derived = BreathRules(gate: gate)
        #expect(derived.dailyHourMinutes == 30)
        #expect(derived.requirement(guardedMinutes: 30, overLimitOpensToday: 0)?.seconds == 5)
        #expect(derived.seconds(forOverLimitOpen: 4) == gate.breathSeconds(forOverLimitOpen: 4))
    }
}
