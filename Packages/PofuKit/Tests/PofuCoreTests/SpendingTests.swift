import Foundation
import Testing
@testable import PofuCore

@Suite("Spending")
struct SpendingTests {
    let economy = Economy(calendar: .istanbul)
    let afternoon = instant(2026, 11, 2, 15)

    /// A wallet that has already received the afternoon's allowance and
    /// holds exactly `balance`.
    func openedWallet(holding balance: Energy) -> Wallet {
        var opened = Wallet()
        economy.openDay(&opened, at: afternoon)
        opened.balance = balance
        return opened
    }

    /// Buys `count` unlocks of 5 minutes, `spacing` minutes apart, starting
    /// at `start`.
    func buyUnlocks(_ count: Int, startingAt start: Date, spacing: Double, into wallet: inout Wallet) throws {
        for index in 0..<count {
            _ = try economy.purchaseUnlock(
                minutes: 5,
                for: testTarget,
                at: start.adding(minutes: Double(index) * spacing),
                from: &wallet
            )
        }
    }

    @Test(arguments: [(5, 5), (10, 10), (15, 15), (30, 30)])
    func basePriceIsOneEnergyPerMinute(minutes: Int, price: Int) throws {
        let quote = try economy.quote(minutes: minutes, at: afternoon, for: Wallet())
        #expect(quote.price == Energy(price))
        #expect(quote.basePrice == Energy(price))
        #expect(quote.escalationSteps == 0)
        #expect(!quote.isNight)
    }

    @Test(arguments: [0, -5, 7, 20, 60])
    func unsupportedDurationsAreRejected(minutes: Int) {
        let error = capturedError { try economy.quote(minutes: minutes, at: afternoon, for: Wallet()) }
        #expect(error as? SpendError == .unsupportedDuration(minutes: minutes))
    }

    @Test func quotesAreSortedShortestFirst() {
        let quotes = economy.quotes(at: afternoon, for: Wallet())
        #expect(quotes.map(\.minutes) == [5, 10, 15, 30])
        #expect(economy.cheapestQuote(at: afternoon, for: Wallet())?.minutes == 5)
    }

    /// Second unlock in the window: × 1.25. Third: × 1.5625. Rounded up once.
    @Test(arguments: [
        (1, 5, 7), (1, 10, 13), (1, 15, 19), (1, 30, 38),
        (2, 5, 8), (2, 10, 16), (2, 15, 24), (2, 30, 47),
        (3, 10, 20), (4, 10, 25),
    ])
    func escalationCompoundsAndRoundsUp(previousUnlocks: Int, minutes: Int, price: Int) throws {
        var wallet = openedWallet(holding: 1_000)
        try buyUnlocks(previousUnlocks, startingAt: afternoon, spacing: 10, into: &wallet)
        let at = afternoon.adding(minutes: Double(previousUnlocks) * 10)
        let quote = try economy.quote(minutes: minutes, at: at, for: wallet)
        #expect(quote.escalationSteps == previousUnlocks)
        #expect(quote.price == Energy(price))
    }

    @Test func escalationWindowIsRollingAndExclusiveOfItsStart() throws {
        var wallet = openedWallet(holding: 100)
        try buyUnlocks(1, startingAt: afternoon, spacing: 0, into: &wallet)
        let justInside = afternoon.adding(hours: 3).addingTimeInterval(-1)
        let exactlyThreeHours = afternoon.adding(hours: 3)
        #expect(economy.escalationSteps(for: wallet, at: justInside) == 1)
        #expect(economy.escalationSteps(for: wallet, at: exactlyThreeHours) == 0)
        #expect(try economy.quote(minutes: 10, at: exactlyThreeHours, for: wallet).price == 10)
    }

    @Test func escalationDecaysOneUnlockAtATime() throws {
        var wallet = openedWallet(holding: 1_000)
        // Unlocks at 15:00, 16:00, 17:00.
        try buyUnlocks(3, startingAt: afternoon, spacing: 60, into: &wallet)
        #expect(economy.escalationSteps(for: wallet, at: afternoon.adding(minutes: 150)) == 3)
        #expect(economy.escalationSteps(for: wallet, at: afternoon.adding(minutes: 185)) == 2)
        #expect(economy.escalationSteps(for: wallet, at: afternoon.adding(minutes: 245)) == 1)
        #expect(economy.escalationSteps(for: wallet, at: afternoon.adding(minutes: 305)) == 0)
    }

    @Test func unlocksAfterTheQuoteInstantDoNotCount() throws {
        var wallet = openedWallet(holding: 100)
        try buyUnlocks(1, startingAt: afternoon, spacing: 0, into: &wallet)
        #expect(economy.escalationSteps(for: wallet, at: afternoon.addingTimeInterval(-60)) == 0)
    }

    @Test(arguments: [
        (22, 59, false), (23, 0, true), (2, 0, true), (5, 59, true), (6, 0, false),
    ])
    func nightPricingDoublesInsideBedtime(hour: Int, minute: Int, isNight: Bool) throws {
        let at = instant(2026, 11, 2, hour, minute)
        let quote = try economy.quote(minutes: 10, at: at, for: Wallet())
        #expect(quote.isNight == isNight)
        #expect(quote.price == (isNight ? 20 : 10))
    }

    @Test func nightAndEscalationMultiply() throws {
        var wallet = Wallet(balance: 500)
        let lateNight = instant(2026, 11, 2, 23, 30)
        _ = try economy.purchaseUnlock(minutes: 10, for: testTarget, at: lateNight, from: &wallet)
        // 10 × 1.25 × 2 = 25. 5 × 1.25 × 2 = 12.5, rounded up.
        let at = lateNight.adding(minutes: 20)
        #expect(try economy.quote(minutes: 10, at: at, for: wallet).price == 25)
        #expect(try economy.quote(minutes: 5, at: at, for: wallet).price == 13)
    }

    @Test func escalationCarriesAcrossMidnight() throws {
        var wallet = Wallet(balance: 500)
        _ = try economy.purchaseUnlock(minutes: 5, for: testTarget, at: instant(2026, 11, 2, 23, 50), from: &wallet)
        let afterMidnight = instant(2026, 11, 3, 0, 10)
        #expect(economy.escalationSteps(for: wallet, at: afterMidnight) == 1)
    }

    @Test func purchaseChargesAndGrantsAPass() throws {
        var wallet = openedWallet(holding: 40)
        let pass = try economy.purchaseUnlock(minutes: 15, for: testTarget, at: afternoon, from: &wallet)
        #expect(wallet.balance == 25)
        #expect(pass.target == testTarget)
        #expect(pass.grantedAt == afternoon)
        #expect(pass.expiresAt == afternoon.adding(minutes: 15))
        #expect(pass.source == .purchased(price: 15))
        #expect(wallet.unlockPurchases == [afternoon])
    }

    @Test func purchaseCanSpendTheExactBalance() throws {
        var wallet = openedWallet(holding: 10)
        _ = try economy.purchaseUnlock(minutes: 10, for: testTarget, at: afternoon, from: &wallet)
        #expect(wallet.balance == .zero)
    }

    @Test func insufficientBalanceThrowsAndChargesNothing() {
        var wallet = openedWallet(holding: 9)
        let error = capturedError {
            try economy.purchaseUnlock(minutes: 10, for: testTarget, at: afternoon, from: &wallet)
        }
        #expect(error as? SpendError == .insufficientBalance(required: 10, available: 9))
        #expect(wallet.balance == 9)
        #expect(wallet.unlockPurchases.isEmpty)
    }

    @Test func purchaseIncludesTodaysPendingAllowance() throws {
        var wallet = Wallet()
        #expect(economy.canAffordAnyUnlock(wallet, at: afternoon))
        _ = try economy.purchaseUnlock(minutes: 15, for: testTarget, at: afternoon, from: &wallet)
        #expect(wallet.balance == .zero)
        #expect(!economy.canAffordAnyUnlock(wallet, at: afternoon))
    }

    @Test func oldPurchasesArePruned() throws {
        var wallet = openedWallet(holding: 1_000)
        try buyUnlocks(3, startingAt: afternoon, spacing: 10, into: &wallet)
        _ = try economy.purchaseUnlock(minutes: 5, for: testTarget, at: afternoon.adding(hours: 5), from: &wallet)
        #expect(wallet.unlockPurchases == [afternoon.adding(hours: 5)])
    }

    @Test func toleranceKeepsExactPricesExact() throws {
        var rules = SpendingRules()
        rules.escalationMultiplier = 1.1
        let tuned = Economy(configuration: EconomyConfiguration(spending: rules), calendar: .istanbul)
        var wallet = Wallet(balance: 100)
        _ = try tuned.purchaseUnlock(minutes: 10, for: testTarget, at: afternoon, from: &wallet)
        // 10 × 1.1 is 11.000000000000002 in floating point; the price is 11.
        #expect(try tuned.quote(minutes: 10, at: afternoon.adding(minutes: 1), for: wallet).price == 11)
    }

    @Test func disabledBedtimeNeverAppliesNightPricing() throws {
        var rules = SpendingRules()
        rules.bedtime = DailyWindow(start: LocalTime(hour: 0), end: LocalTime(hour: 0))
        let tuned = Economy(configuration: EconomyConfiguration(spending: rules), calendar: .istanbul)
        #expect(try tuned.quote(minutes: 10, at: instant(2026, 11, 2, 2), for: Wallet()).price == 10)
    }
}
