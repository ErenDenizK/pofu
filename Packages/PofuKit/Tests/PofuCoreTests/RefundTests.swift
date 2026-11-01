import Foundation
import Testing
@testable import PofuCore

@Suite("Ending passes early")
struct RefundTests {
    let economy = Economy(calendar: .istanbul)
    var gatekeeper: Gatekeeper { Gatekeeper(economy: economy) }
    let noon = instant(2026, 11, 2, 12)

    /// A state with enough seeds for any test purchase; the day's
    /// allowance of 15 arrives on top with the first operation.
    func funded() -> PofuState {
        PofuState(wallet: Wallet(balance: 100))
    }

    /// Buys a pass directly and records it in the ledger.
    func buy(_ minutes: Int, at date: Date, in state: inout PofuState) throws -> Pass {
        let pass = try economy.purchaseUnlock(minutes: minutes, for: testTarget, at: date, from: &state.wallet)
        state.passes.grant(pass)
        return pass
    }

    @Test func refundsUnusedWholeMinutesAtThePricePaid() throws {
        var state = PofuState()
        let pass = try buy(10, at: noon, in: &state)
        #expect(state.wallet.balance == 5)

        // 3.5 minutes used: 6.5 left, 6 whole minutes at 1 seed each.
        let ending = try #require(gatekeeper.endPass(id: pass.id, at: noon.adding(minutes: 3.5), state: &state))
        #expect(ending.refund == 6)
        #expect(state.wallet.balance == 11)
        #expect(state.passes.passes.isEmpty)
    }

    @Test func usesTheEscalatedPriceActuallyPaid() throws {
        var state = funded()
        _ = try buy(5, at: noon, in: &state)
        let second = try buy(10, at: noon.adding(minutes: 1), in: &state)
        #expect(second.source == .purchased(price: 13))

        // Ended at once: all 10 minutes come back, which is the full price.
        #expect(economy.refund(for: second, endingAt: second.grantedAt) == 13)
        // A second in: 9 whole minutes, ⌊9 × 13 ÷ 10⌋ = 11.
        #expect(economy.refund(for: second, endingAt: second.grantedAt.addingTimeInterval(1)) == 11)
    }

    @Test func usesTheNightPriceActuallyPaid() throws {
        var state = funded()
        let late = instant(2026, 11, 2, 23, 30)
        let pass = try buy(10, at: late, in: &state)
        #expect(pass.source == .purchased(price: 20))
        #expect(economy.refund(for: pass, endingAt: late.adding(minutes: 5)) == 10)
    }

    @Test func freeAndFriendPassesRefundNothingButStillEnd() throws {
        var state = PofuState()
        guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: noon, state: &state) else {
            Issue.record("Expected an intervention")
            return
        }
        let record = try gatekeeper.resolve(attempt, with: .proceed, at: noon, state: &state)
        let pass = try #require(record.outcome.pass)
        let balance = state.wallet.balance

        let ending = try #require(gatekeeper.endPass(id: pass.id, at: noon.adding(minutes: 1), state: &state))
        #expect(ending.refund == .zero)
        #expect(state.wallet.balance == balance)
        // Protection is back: the next open is an attempt again.
        guard case .intervene = gatekeeper.beginCheckIn(for: testTarget, at: noon.adding(minutes: 2), state: &state) else {
            Issue.record("Expected an intervention after ending the pass")
            return
        }

        let friend = Pass(target: testTarget, grantedAt: noon, minutes: 10, source: .friendApproved)
        #expect(economy.refund(for: friend, endingAt: noon) == .zero)
        let emergency = Pass(target: testTarget, grantedAt: noon, minutes: 3, source: .emergency)
        #expect(economy.refund(for: emergency, endingAt: noon) == .zero)
    }

    @Test func anExpiredOrUnknownPassRefundsNothing() throws {
        var state = PofuState()
        let pass = try buy(5, at: noon, in: &state)
        #expect(economy.refund(for: pass, endingAt: noon.adding(minutes: 5)) == .zero)
        #expect(gatekeeper.endPass(id: UUID(), at: noon, state: &state) == nil)
    }

    @Test(arguments: [5, 10, 15, 30])
    func neverRefundsMoreThanWasPaidAndShrinksOverTime(minutes: Int) throws {
        var state = funded()
        _ = try buy(5, at: noon, in: &state)
        let pass = try buy(minutes, at: noon.adding(minutes: 1), in: &state)
        guard case .purchased(let price) = pass.source else {
            Issue.record("Expected a purchased pass")
            return
        }
        var previous = price
        for second in stride(from: 0, through: minutes * 60, by: 7) {
            let refund = economy.refund(for: pass, endingAt: pass.grantedAt.addingTimeInterval(TimeInterval(second)))
            #expect(refund >= .zero)
            #expect(refund <= previous)
            previous = refund
        }
        #expect(previous == .zero)
    }

    @Test func exactMinuteBoundariesCountAsWholeMinutes() throws {
        var state = funded()
        let pass = try buy(30, at: noon, in: &state)
        for used in 0...30 {
            let refund = economy.refund(for: pass, endingAt: noon.adding(minutes: Double(used)))
            #expect(refund == Energy(used == 30 ? 0 : 30 - used))
        }
    }

    @Test func voidingAnUnusablePurchaseRefundsInFullAndUndoesEscalation() throws {
        var state = funded()
        _ = try buy(5, at: noon, in: &state)
        let second = try buy(10, at: noon.adding(minutes: 1), in: &state)
        let balanceBefore = state.wallet.balance

        let ending = try #require(gatekeeper.voidPass(id: second.id, state: &state))
        #expect(ending.refund == 13)
        #expect(state.wallet.balance == balanceBefore + 13)
        #expect(economy.escalationSteps(for: state.wallet, at: noon.adding(minutes: 2)) == 1)
    }

    @Test func voidingAnEmergencyPassMakesItAvailableAgain() throws {
        var state = PofuState()
        let pass = try #require(economy.grantEmergencyPass(for: testTarget, at: noon, from: &state.wallet))
        state.passes.grant(pass)
        #expect(!economy.isEmergencyPassAvailable(in: state.wallet, at: noon))
        _ = gatekeeper.voidPass(id: pass.id, state: &state)
        #expect(economy.isEmergencyPassAvailable(in: state.wallet, at: noon))
    }
}

@Suite("Skips never earn")
struct SkipsNeverEarnTests {
    let economy = Economy(calendar: .istanbul)
    let noon = instant(2026, 11, 2, 12)

    @Test(arguments: [EconomyConfiguration.standard, EconomyConfiguration(dailyAllowance: 0)])
    func skippingOnEveryRungLeavesTheWalletUntouched(configuration: EconomyConfiguration) throws {
        let gatekeeper = Gatekeeper(economy: Economy(configuration: configuration, calendar: .istanbul))
        var state = PofuState()
        // The allowance arrives with the first interaction; skips add nothing.
        _ = gatekeeper.economy.openDay(&state.wallet, at: noon)
        let opening = state.wallet

        var rungs: Set<FrictionRung> = []
        for index in 0..<40 {
            let at = noon.adding(minutes: Double(index))
            guard case .intervene(let attempt) = gatekeeper.beginCheckIn(for: testTarget, at: at, state: &state) else {
                Issue.record("Expected an intervention")
                return
            }
            rungs.insert(attempt.rung)
            try gatekeeper.resolve(attempt, with: .resist, at: at, state: &state)
            #expect(state.wallet.balance == opening.balance)
            #expect(state.wallet.activityEnergy(on: economy.day(of: at)) == .zero)
        }
        #expect(rungs.count >= 3)
        #expect(state.checkIns.allSatisfy { $0.outcome.isResisted })
    }
}
