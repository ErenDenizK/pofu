import Foundation
import Testing
import PofuCore

@Suite("Daily allowance")
struct AllowanceTests {
    let economy = Economy(calendar: .istanbul)

    @Test func firstInteractionOfTheDayGrantsTheAllowance() {
        var wallet = Wallet()
        let granted = economy.openDay(&wallet, at: instant(2026, 11, 2, 8))
        #expect(granted == 15)
        #expect(wallet.balance == Energy(15))
        #expect(wallet.lastAllowanceDay == LocalDay(year: 2026, month: 11, day: 2))
    }

    @Test func allowanceIsGrantedOncePerDay() {
        var wallet = Wallet()
        economy.openDay(&wallet, at: instant(2026, 11, 2, 0, 0, 0))
        var granted = economy.openDay(&wallet, at: instant(2026, 11, 2, 13))
        #expect(granted == .zero)
        granted = economy.openDay(&wallet, at: instant(2026, 11, 2, 23, 59, 59))
        #expect(granted == .zero)
        #expect(wallet.balance == Energy(15))
    }

    @Test func midnightStartsANewAllowance() {
        var wallet = Wallet()
        economy.openDay(&wallet, at: instant(2026, 11, 2, 23, 59, 59))
        let granted = economy.openDay(&wallet, at: instant(2026, 11, 3, 0, 0, 0))
        #expect(granted == 15)
        #expect(wallet.balance == Energy(30))
    }

    @Test func balanceCarriesOverAndMissedDaysAreNotBackFilled() {
        var wallet = Wallet(balance: 4)
        economy.openDay(&wallet, at: instant(2026, 11, 2))
        economy.openDay(&wallet, at: instant(2026, 11, 6))
        #expect(wallet.balance == Energy(4 + 15 + 15))
    }

    @Test func clockMovingBackwardsNeverGrantsTwice() {
        var wallet = Wallet()
        economy.openDay(&wallet, at: instant(2026, 11, 3))
        var granted = economy.openDay(&wallet, at: instant(2026, 11, 2))
        #expect(granted == .zero)
        granted = economy.openDay(&wallet, at: instant(2026, 11, 3, 18))
        #expect(granted == .zero)
        #expect(wallet.balance == Energy(15))
    }

    @Test func allowanceFollowsTheLocalDayNotUTC() {
        var wallet = Wallet()
        // 02:00 in Istanbul on Nov 3 is still Nov 2 in UTC; Istanbul is a new day.
        economy.openDay(&wallet, at: instant(2026, 11, 2, 20))
        let granted = economy.openDay(&wallet, at: instant(2026, 11, 3, 2))
        #expect(granted == 15)
    }

    @Test func negativeOpeningBalanceIsClamped() {
        #expect(Wallet(balance: -10).balance == .zero)
    }
}

@Suite("Earning")
struct EarningTests {
    let economy = Economy(calendar: .istanbul)
    let evening = instant(2026, 11, 2, 19)

    @Test(arguments: [
        (0.0, 0), (1.0, 0), (1.9, 0), (2.0, 1), (3.0, 1), (25.0, 12), (60.0, 30), (90.5, 45),
    ])
    func honorEarnsOneEnergyPerTwoWholeMinutes(minutes: Double, expected: Int) {
        #expect(economy.grossEnergy(for: session(minutes, .honor, endingAt: evening)) == Energy(expected))
    }

    @Test(arguments: [VerificationLevel.passive, .structural, .active])
    func verifiedActivitiesEarnTheMultiplier(level: VerificationLevel) {
        #expect(economy.grossEnergy(for: session(60, level, endingAt: evening)) == 45)
        // 25 min × 0.5 × 1.5 = 18.75, rounded down.
        #expect(economy.grossEnergy(for: session(25, level, endingAt: evening)) == 18)
        #expect(economy.grossEnergy(for: session(1, level, endingAt: evening)) == 0)
    }

    @Test func sessionEndingBeforeItStartsEarnsNothing() {
        let backwards = ActivitySession(
            kind: .walk,
            verification: .honor,
            startedAt: evening,
            endedAt: evening.adding(minutes: -30)
        )
        #expect(backwards.wholeMinutes == 0)
        var wallet = Wallet()
        let granted = economy.earn(backwards, into: &wallet).earned
        #expect(granted == .zero)
    }

    @Test func earningCreditsTheBalanceAfterTheAllowance() {
        var wallet = Wallet()
        let result = economy.earn(session(60, .honor, endingAt: evening), into: &wallet)
        #expect(result == EarningResult(earned: 30))
        #expect(wallet.balance == Energy(15 + 30))
        #expect(wallet.activityEnergy(on: economy.day(of: evening)) == 30)
    }

    @Test func honorCapStopsAtExactly120AndReportsTheExcess() {
        var wallet = Wallet()
        let day = economy.day(of: evening)
        // 200 min = 100 energy, under the cap.
        let first = economy.earn(session(200, .honor, endingAt: evening), into: &wallet)
        #expect(first == EarningResult(earned: 100))
        // 60 min = 30 energy, of which only 20 fit.
        let second = economy.earn(session(60, .honor, endingAt: evening.adding(minutes: 70)), into: &wallet)
        #expect(second.earned == 20)
        #expect(second.forfeitedToCap == 10)
        #expect(second.gross == 30)
        #expect(wallet.honorEnergy(on: day) == 120)
        // Anything further is fully forfeited.
        let third = economy.earn(session(10, .honor, endingAt: evening.adding(minutes: 90)), into: &wallet)
        #expect(third == EarningResult(earned: .zero, forfeitedToCap: 5))
        #expect(wallet.balance == Energy(15 + 120))
    }

    @Test func verifiedEarningsAreNeitherCappedNorCountedTowardTheHonorCap() {
        var wallet = Wallet()
        let day = economy.day(of: evening)
        economy.earn(session(240, .honor, endingAt: evening), into: &wallet)
        #expect(wallet.honorEnergy(on: day) == 120)
        // Same local day: 400 minutes ending a minute after the honor session.
        let verified = economy.earn(session(400, .structural, kind: .focus, endingAt: evening.adding(minutes: 1)), into: &wallet)
        #expect(verified == EarningResult(earned: 300))
        #expect(wallet.honorEnergy(on: day) == 120)
        #expect(wallet.activityEnergy(on: day) == 420)
    }

    @Test func honorCapResetsAtLocalMidnight() {
        var wallet = Wallet()
        economy.earn(session(240, .honor, endingAt: instant(2026, 11, 2, 23, 59)), into: &wallet)
        let nextDay = economy.earn(session(20, .honor, endingAt: instant(2026, 11, 3, 0, 30)), into: &wallet)
        #expect(nextDay == EarningResult(earned: 10))
    }

    @Test func sessionCrossingMidnightCountsForTheDayItEnds() {
        var wallet = Wallet()
        let end = instant(2026, 11, 3, 0, 20)
        economy.earn(session(60, .honor, endingAt: end), into: &wallet)
        #expect(wallet.honorEnergy(on: LocalDay(year: 2026, month: 11, day: 3)) == 30)
        #expect(wallet.honorEnergy(on: LocalDay(year: 2026, month: 11, day: 2)) == .zero)
    }

    @Test func lateLoggedSessionCountsAgainstItsOwnDaysCap() {
        var wallet = Wallet()
        economy.earn(session(240, .honor, endingAt: instant(2026, 11, 2, 20)), into: &wallet)
        economy.openDay(&wallet, at: instant(2026, 11, 3, 9))
        // Logged on Nov 3 but ended on Nov 2, whose cap is already full.
        let late = economy.earn(session(30, .honor, endingAt: instant(2026, 11, 2, 22)), into: &wallet)
        #expect(late == EarningResult(earned: .zero, forfeitedToCap: 15))
    }

    @Test func sessionsOlderThanTheRetainedHistoryAreNotCredited() {
        var wallet = Wallet()
        economy.openDay(&wallet, at: instant(2026, 11, 20))
        let old = economy.earn(session(60, .structural, endingAt: instant(2026, 11, 12)), into: &wallet)
        #expect(old == EarningResult(earned: .zero, wasStale: true))
        let edge = economy.earn(session(60, .structural, endingAt: instant(2026, 11, 13)), into: &wallet)
        #expect(edge.earned == 45)
    }

    @Test func historyIsPrunedToTheRetentionWindow() {
        var wallet = Wallet()
        economy.earn(session(60, .honor, endingAt: instant(2026, 11, 1)), into: &wallet)
        economy.openDay(&wallet, at: instant(2026, 11, 20))
        #expect(wallet.honorEarnedByDay.isEmpty)
        #expect(wallet.activityEnergyByDay.isEmpty)
    }

    @Test func toleranceKeepsExactProductsExact() {
        let tuned = Economy(
            configuration: EconomyConfiguration(earning: EarningRules(energyPerMinute: 1.15, verifiedMultiplier: 1)),
            calendar: .istanbul
        )
        // 100 × 1.15 = 115 exactly, though binary floating point says 114.999…
        #expect(tuned.grossEnergy(for: session(100, .honor, endingAt: evening)) == 115)
    }
}

@Suite("Steps")
struct StepTests {
    let economy = Economy(calendar: .istanbul)
    let morning = instant(2026, 11, 2, 9)

    @Test func stepsEarnOneEnergyPer500() {
        var wallet = Wallet()
        let granted = economy.creditSteps(dailyTotal: 1_499, on: morning, into: &wallet)
        #expect(granted == 2)
        #expect(wallet.balance == Energy(15 + 2))
    }

    @Test func cumulativeTotalsAreCreditedIncrementally() {
        var wallet = Wallet()
        var granted = economy.creditSteps(dailyTotal: 2_000, on: morning, into: &wallet)
        #expect(granted == 4)
        granted = economy.creditSteps(dailyTotal: 2_000, on: morning.adding(hours: 1), into: &wallet)
        #expect(granted == .zero)
        granted = economy.creditSteps(dailyTotal: 2_499, on: morning.adding(hours: 2), into: &wallet)
        #expect(granted == .zero)
        granted = economy.creditSteps(dailyTotal: 5_100, on: morning.adding(hours: 3), into: &wallet)
        #expect(granted == 6)
        #expect(wallet.balance == Energy(15 + 10))
    }

    @Test func shrinkingTotalsNeverClawBack() {
        var wallet = Wallet()
        economy.creditSteps(dailyTotal: 5_000, on: morning, into: &wallet)
        var granted = economy.creditSteps(dailyTotal: 3_000, on: morning.adding(hours: 1), into: &wallet)
        #expect(granted == .zero)
        granted = economy.creditSteps(dailyTotal: 5_600, on: morning.adding(hours: 2), into: &wallet)
        #expect(granted == 1)
        #expect(wallet.balance == Energy(15 + 11))
    }

    @Test func eachDayStartsFromZero() {
        var wallet = Wallet()
        economy.creditSteps(dailyTotal: 10_000, on: morning, into: &wallet)
        let granted = economy.creditSteps(dailyTotal: 1_000, on: morning.adding(hours: 24), into: &wallet)
        #expect(granted == 2)
    }

    @Test func stepsAreNotLimitedByTheHonorCap() {
        var wallet = Wallet()
        economy.earn(session(240, .honor, endingAt: morning), into: &wallet)
        let granted = economy.creditSteps(dailyTotal: 30_000, on: morning, into: &wallet)
        #expect(granted == 60)
    }

    @Test func negativeOrZeroTotalsEarnNothing() {
        var wallet = Wallet()
        var granted = economy.creditSteps(dailyTotal: -500, on: morning, into: &wallet)
        #expect(granted == .zero)
        granted = economy.creditSteps(dailyTotal: 0, on: morning, into: &wallet)
        #expect(granted == .zero)
    }

    @Test func staleStepTotalsAreIgnored() {
        var wallet = Wallet()
        economy.openDay(&wallet, at: instant(2026, 11, 20))
        let granted = economy.creditSteps(dailyTotal: 10_000, on: instant(2026, 11, 2), into: &wallet)
        #expect(granted == .zero)
    }
}
